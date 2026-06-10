import Foundation

struct SmartAlertService {
    private let dismissedIDsKey = AppPreferenceKeys.dismissedSmartAlertIDs

    func generateAlerts(
        expenses: [Expense],
        goalForecasts: [GoalForecast],
        comparisons: [SpendingComparison],
        strings: AppStrings = .current(),
        calendar: Calendar = .current
    ) -> [SmartAlert] {
        guard alertsEnabled else { return [] }

        let safeExpenses = expenses.filter { $0.amount.isFinite }
        let dismissedIDs = dismissedAlertIDs()
        let now = Date.now
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now)
        let monthInterval = calendar.dateInterval(of: .month, for: now)

        var alerts: [SmartAlert] = []

        if safeExpenses.isEmpty {
            alerts.append(noDataAlert(strings: strings, createdAt: now))
            return filteredAndSorted(alerts, dismissedIDs: dismissedIDs)
        }

        alerts.append(contentsOf: goalAlerts(goalForecasts: goalForecasts, strings: strings, createdAt: now))

        if let alert = todayAboveAverageAlert(expenses: safeExpenses, monthInterval: monthInterval, calendar: calendar, strings: strings, createdAt: now) {
            alerts.append(alert)
        }

        if let alert = categorySpikeAlert(expenses: safeExpenses, weekInterval: weekInterval, calendar: calendar, strings: strings, createdAt: now) {
            alerts.append(alert)
        }

        if let alert = positiveTrendAlert(comparisons: comparisons, strings: strings, createdAt: now) {
            alerts.append(alert)
        }

        return filteredAndSorted(alerts, dismissedIDs: dismissedIDs)
    }

    func dismissAlert(id: String) {
        var ids = dismissedAlertIDs()
        ids.insert(id)
        UserDefaults.standard.set(Array(ids), forKey: dismissedIDsKey)
    }

    func clearDismissedAlerts() {
        UserDefaults.standard.removeObject(forKey: dismissedIDsKey)
    }

    private func filteredAndSorted(_ alerts: [SmartAlert], dismissedIDs: Set<String>) -> [SmartAlert] {
        alerts
            .map { alert in
                var copy = alert
                copy.isDismissed = dismissedIDs.contains(alert.id)
                return copy
            }
            .filter { !$0.isDismissed }
            .sorted { lhs, rhs in
                if lhs.severity.priority == rhs.severity.priority {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.severity.priority > rhs.severity.priority
            }
    }

    private func dismissedAlertIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: dismissedIDsKey) ?? [])
    }

    private var alertsEnabled: Bool {
        if UserDefaults.standard.object(forKey: AppPreferenceKeys.smartAlertsEnabled) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: AppPreferenceKeys.smartAlertsEnabled)
    }

    private func noDataAlert(strings: AppStrings, createdAt: Date) -> SmartAlert {
        SmartAlert(
            id: "no-data",
            title: strings.smartAlertsNoDataTitle,
            message: strings.smartAlertsNoDataMessage,
            severity: .info,
            type: .noData,
            createdAt: createdAt
        )
    }

    private func goalAlerts(
        goalForecasts: [GoalForecast],
        strings: AppStrings,
        createdAt: Date
    ) -> [SmartAlert] {
        goalForecasts.compactMap { forecast in
            guard forecast.status != .safe else { return nil }

            let cadenceText = forecast.goalType == .weekly ? strings.goalsWeeklyTitle : strings.goalsMonthlyTitle
            let id = goalAlertID(for: forecast)
            let (severity, message): (SmartAlertSeverity, String)

            switch forecast.status {
            case .watch:
                guard forecast.remainingDailyBudget.isFinite else { return nil }
                severity = .warning
                message = forecast.goalType == .weekly
                    ? String(format: strings.smartAlertsGoalWatchWeeklyMessageTemplate, cadenceText, currency(forecast.remainingDailyBudget))
                    : String(format: strings.smartAlertsGoalWatchMonthlyMessageTemplate, cadenceText, currency(forecast.remainingDailyBudget))
            case .risk:
                guard forecast.projectedOverLimitAmount.isFinite else { return nil }
                severity = .critical
                message = forecast.goalType == .weekly
                    ? String(format: strings.smartAlertsGoalRiskWeeklyMessageTemplate, cadenceText, currency(forecast.projectedOverLimitAmount))
                    : String(format: strings.smartAlertsGoalRiskMonthlyMessageTemplate, cadenceText, currency(forecast.projectedOverLimitAmount))
            case .over:
                guard forecast.projectedOverLimitAmount.isFinite else { return nil }
                severity = .critical
                message = forecast.goalType == .weekly
                    ? String(format: strings.smartAlertsGoalOverWeeklyMessageTemplate, cadenceText, currency(forecast.projectedOverLimitAmount))
                    : String(format: strings.smartAlertsGoalOverMonthlyMessageTemplate, cadenceText, currency(forecast.projectedOverLimitAmount))
            case .safe:
                return nil
            }

            return SmartAlert(
                id: id,
                title: strings.smartAlertsGoalRiskTitle,
                message: message,
                severity: severity,
                type: .goalRisk,
                createdAt: createdAt
            )
        }
    }

    private func todayAboveAverageAlert(
        expenses: [Expense],
        monthInterval: DateInterval?,
        calendar: Calendar,
        strings: AppStrings,
        createdAt: Date
    ) -> SmartAlert? {
        guard let monthInterval else { return nil }

        let todayTotal = expenses
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }
        guard todayTotal.isFinite else { return nil }

        let currentMonthExpenses = expenses.filter { monthInterval.contains($0.date) }
        guard !currentMonthExpenses.isEmpty else { return nil }

        let elapsedDays = max(calendar.component(.day, from: .now), 1)
        let dailyAverage = currentMonthExpenses.reduce(0) { $0 + $1.amount } / Double(elapsedDays)
        guard dailyAverage.isFinite, dailyAverage > 0 else { return nil }

        let ratio = todayTotal / dailyAverage
        guard ratio >= 1.25, todayTotal > dailyAverage + 0.01 else { return nil }

        let delta = todayTotal - dailyAverage
        let severity: SmartAlertSeverity = ratio >= 2.0 ? .critical : .warning
        let id = "today-average-\(currentDateKey(calendar: calendar))-\(bucket(ratio * 100))"

        return SmartAlert(
            id: id,
            title: strings.smartAlertsTodayAboveAverageTitle,
            message: String(
                format: strings.smartAlertsTodayAboveAverageMessageTemplate,
                currency(delta),
                String(format: "%.0f%%", (ratio - 1) * 100)
            ),
            severity: severity,
            type: .overspendToday,
            createdAt: createdAt
        )
    }

    private func categorySpikeAlert(
        expenses: [Expense],
        weekInterval: DateInterval?,
        calendar: Calendar,
        strings: AppStrings,
        createdAt: Date
    ) -> SmartAlert? {
        guard let weekInterval else { return nil }

        let currentWeekExpenses = expenses.filter { weekInterval.contains($0.date) }
        let previousWeekInterval = calendar.date(byAdding: .weekOfYear, value: -1, to: weekInterval.start).flatMap {
            calendar.dateInterval(of: .weekOfYear, for: $0)
        }
        let previousWeekExpenses = previousWeekInterval.map { interval in
            expenses.filter { interval.contains($0.date) }
        } ?? []

        let currentTotals = groupedTotals(for: currentWeekExpenses)
        let previousTotals = groupedTotals(for: previousWeekExpenses)

        let spike = currentTotals.compactMap { categoryID, currentTotal -> (category: ExpenseCategory, current: Double, previous: Double, change: Double, percent: Double)? in
            guard currentTotal.isFinite else { return nil }
            let previous = previousTotals[categoryID] ?? 0
            let delta = currentTotal - previous
            guard delta > 0 else { return nil }
            guard previous > 0 else { return nil }
            let percent = (delta / previous) * 100
            guard percent.isFinite else { return nil }
            guard percent >= 50 else { return nil }
            guard let category = currentWeekExpenses.first(where: { $0.category.id == categoryID })?.category else {
                return nil
            }
            return (category: category, current: currentTotal, previous: previous, change: delta, percent: percent)
        }
        .sorted { lhs, rhs in
            if lhs.percent == rhs.percent {
                return lhs.change > rhs.change
            }
            return lhs.percent > rhs.percent
        }
        .first

        guard let spike else { return nil }

        let severity: SmartAlertSeverity = spike.percent >= 100 ? .critical : .warning
        let id = "category-spike-\(spike.category.slug)-\(weekStartKey(from: weekInterval.start))-\(bucket(spike.percent))"

        return SmartAlert(
            id: id,
            title: strings.smartAlertsCategorySpikeTitle,
            message: String(
                format: strings.smartAlertsCategorySpikeMessageTemplate,
                spike.category.displayName,
                currency(spike.change),
                String(format: "%.0f%%", spike.percent)
            ),
            severity: severity,
            type: .categorySpike,
            createdAt: createdAt
        )
    }

    private func positiveTrendAlert(
        comparisons: [SpendingComparison],
        strings: AppStrings,
        createdAt: Date
    ) -> SmartAlert? {
        guard let comparison = comparisons.first(where: { $0.period == .weekVsLastWeek && $0.hasPreviousData }) else {
            return nil
        }

        guard comparison.percentChange.isFinite, comparison.deltaAmount.isFinite else {
            return nil
        }

        guard comparison.direction == .down, comparison.percentChange >= 10 else {
            return nil
        }

        let id = "positive-trend-week-\(bucket(comparison.percentChange))"

        return SmartAlert(
            id: id,
            title: strings.smartAlertsPositiveTrendTitle,
            message: String(
                format: strings.smartAlertsPositiveTrendMessageTemplate,
                currency(abs(comparison.deltaAmount)),
                String(format: "%.0f%%", comparison.percentChange)
            ),
            severity: .success,
            type: .positiveTrend,
            createdAt: createdAt
        )
    }

    private func groupedTotals(for expenses: [Expense]) -> [ExpenseCategory.ID: Double] {
        Dictionary(grouping: expenses, by: { $0.category.id }).mapValues { items in
            items.reduce(0) { $0 + $1.amount }
        }
    }

    private func goalAlertID(for forecast: GoalForecast) -> String {
        "goal-\(forecast.goalType.rawValue)-\(forecast.status.rawValue)-\(bucket(forecast.percentUsed))"
    }

    private func currentDateKey(calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: .now)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private func weekStartKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }

    private func bucket(_ value: Double) -> Int {
        guard value.isFinite else { return 0 }
        return Int((value / 5.0).rounded(.down) * 5)
    }

    private func currency(_ amount: Double) -> String {
        String(format: "$%.2f", amount)
    }
}
