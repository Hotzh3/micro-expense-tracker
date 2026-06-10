import Foundation

struct SmartInsightsService {
    func generateInsights(
        expenses: [Expense],
        goals: SpendingGoals,
        calendar: Calendar = .current,
        strings: AppStrings = .current()
    ) -> [SmartInsight] {
        let safeExpenses = expenses.filter { $0.amount.isFinite }

        guard !safeExpenses.isEmpty else {
            return [
                SmartInsight(
                    title: strings.smartInsightsNoDataTitle,
                    message: strings.smartInsightsNoDataMessage,
                    type: .neutral,
                    priority: 0
                )
            ]
        }

        let now = Date.now
        let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: now)
        let currentMonthInterval = calendar.dateInterval(of: .month, for: now)
        let currentWeekExpenses = expensesForInterval(currentWeekInterval, source: safeExpenses)
        let previousWeekExpenses = previousWeekExpenses(from: currentWeekInterval, expenses: safeExpenses, calendar: calendar)
        let currentMonthExpenses = expensesForInterval(currentMonthInterval, source: safeExpenses)

        var insights: [SmartInsight] = []
        insights.append(contentsOf: goalInsights(goals: goals, currentWeekExpenses: currentWeekExpenses, currentMonthExpenses: currentMonthExpenses, calendar: calendar, strings: strings))
        insights.append(contentsOf: spendingChangeInsights(currentWeekExpenses: currentWeekExpenses, previousWeekExpenses: previousWeekExpenses, strings: strings))
        insights.append(contentsOf: topCategoryInsights(currentWeekExpenses: currentWeekExpenses, monthExpenses: currentMonthExpenses, strings: strings))
        insights.append(contentsOf: dailyAverageInsights(currentWeekInterval: currentWeekInterval, currentMonthInterval: currentMonthInterval, currentWeekExpenses: currentWeekExpenses, currentMonthExpenses: currentMonthExpenses, calendar: calendar, strings: strings))

        guard !insights.isEmpty else {
            return [
                SmartInsight(
                    title: strings.smartInsightsNoDataTitle,
                    message: strings.smartInsightsNoDataMessage,
                    type: .neutral,
                    priority: 0
                )
            ]
        }

        return insights
            .sorted { lhs, rhs in
                if lhs.priority == rhs.priority {
                    return lhs.title < rhs.title
                }
                return lhs.priority > rhs.priority
            }
    }

    private func goalInsights(
        goals: SpendingGoals,
        currentWeekExpenses: [Expense],
        currentMonthExpenses: [Expense],
        calendar: Calendar,
        strings: AppStrings
    ) -> [SmartInsight] {
        var insights: [SmartInsight] = []

        if let weeklyGoal = goals.weekly {
            insights.append(
                goalInsight(
                    cadence: .weekly,
                    goal: weeklyGoal,
                    spent: currentWeekExpenses.reduce(0) { $0 + $1.amount },
                    calendar: calendar,
                    strings: strings
                )
            )
        }

        if let monthlyGoal = goals.monthly {
            insights.append(
                goalInsight(
                    cadence: .monthly,
                    goal: monthlyGoal,
                    spent: currentMonthExpenses.reduce(0) { $0 + $1.amount },
                    calendar: calendar,
                    strings: strings
                )
            )
        }

        return insights
    }

    private func goalInsight(
        cadence: SpendingGoalCadence,
        goal: SpendingGoal,
        spent: Double,
        calendar: Calendar,
        strings: AppStrings
    ) -> SmartInsight {
        guard goal.limit.isFinite, goal.limit > 0, spent.isFinite else {
            return SmartInsight(
                title: strings.smartInsightsNoDataTitle,
                message: strings.smartInsightsNoDataMessage,
                type: .neutral,
                priority: 0
            )
        }

        let remaining = max(goal.limit - spent, 0)
        let overage = max(spent - goal.limit, 0)
        let title: String
        let message: String
        let type: SmartInsightType
        let priority: Int
        let amount: Double

        enum GoalInsightStatus {
            case onTrack
            case closeToLimit
            case limitReached
        }

        let status: GoalInsightStatus
        if spent >= goal.limit {
            status = .limitReached
        } else if remaining <= goal.limit * 0.25 {
            status = .closeToLimit
        } else {
            status = .onTrack
        }

        switch status {
        case .limitReached:
            title = strings.smartInsightsGoalRiskTitle
            message = cadence == .weekly
                ? String(format: strings.smartInsightsGoalRiskWeeklyLimitReachedMessage, currency(overage))
                : String(format: strings.smartInsightsGoalRiskMonthlyLimitReachedMessage, currency(overage))
            type = .goalRisk
            priority = 100
            amount = overage
        case .closeToLimit:
            title = strings.smartInsightsGoalRiskTitle
            message = cadence == .weekly
                ? String(format: strings.smartInsightsGoalRiskWeeklyCloseToLimitMessage, currency(remaining))
                : String(format: strings.smartInsightsGoalRiskMonthlyCloseToLimitMessage, currency(remaining))
            type = .goalRisk
            priority = 95
            amount = remaining
        case .onTrack:
            title = strings.smartInsightsPositiveTrendTitle
            message = cadence == .weekly
                ? String(format: strings.goalsWeeklyOnTrackMessageTemplate, currency(remainingDailyBudget(remaining: remaining, cadence: cadence, calendar: calendar)))
                : String(
                    format: strings.goalsMonthlyOnTrackMessageTemplate,
                    currency(remainingDailyBudget(remaining: remaining, cadence: cadence, calendar: calendar)),
                    currency(projectedSpend(spent: spent, cadence: cadence, calendar: calendar))
                )
            type = .positiveTrend
            priority = 60
            amount = remaining
        }

        return SmartInsight(
            title: title,
            message: message,
            type: type,
            priority: priority,
            amount: amount
        )
    }

    private func spendingChangeInsights(
        currentWeekExpenses: [Expense],
        previousWeekExpenses: [Expense],
        strings: AppStrings
    ) -> [SmartInsight] {
        let currentWeekTotal = currentWeekExpenses.reduce(0) { $0 + $1.amount }
        let previousWeekTotal = previousWeekExpenses.reduce(0) { $0 + $1.amount }

        guard currentWeekTotal > 0, previousWeekTotal > 0 else {
            return []
        }

        let difference = currentWeekTotal - previousWeekTotal
        guard abs(difference) >= 0.01 else { return [] }

        let percentChange = (difference / previousWeekTotal) * 100

        if difference > 0 {
            return [
                SmartInsight(
                    title: strings.smartInsightsSpendingIncreaseTitle,
                    message: String(format: strings.smartInsightsSpendingIncreaseMessage, currency(difference), signedPercent(percentChange)),
                    type: .spendingIncrease,
                    priority: 90,
                    amount: difference,
                    percentChange: percentChange
                )
            ]
        } else {
            return [
                SmartInsight(
                    title: strings.smartInsightsSpendingDecreaseTitle,
                    message: String(format: strings.smartInsightsSpendingDecreaseMessage, currency(abs(difference)), signedPercent(percentChange)),
                    type: .spendingDecrease,
                    priority: 85,
                    amount: abs(difference),
                    percentChange: percentChange
                )
            ]
        }
    }

    private func topCategoryInsights(
        currentWeekExpenses: [Expense],
        monthExpenses: [Expense],
        strings: AppStrings
    ) -> [SmartInsight] {
        let weekTotal = currentWeekExpenses.reduce(0) { $0 + $1.amount }
        let monthTotal = monthExpenses.reduce(0) { $0 + $1.amount }
        var insights: [SmartInsight] = []

        if let topWeek = topCategoryInsight(
            expenses: currentWeekExpenses,
            total: weekTotal,
            title: strings.smartInsightsTopCategoryWeekTitle,
            messageTemplate: strings.smartInsightsTopCategoryWeekMessage,
            priority: 80
        ) {
            insights.append(topWeek)
        }

        if let topMonth = topCategoryInsight(
            expenses: monthExpenses,
            total: monthTotal,
            title: strings.smartInsightsTopCategoryMonthTitle,
            messageTemplate: strings.smartInsightsTopCategoryMonthMessage,
            priority: 78
        ) {
            insights.append(topMonth)
        }

        return insights
    }

    private func topCategoryInsight(
        expenses: [Expense],
        total: Double,
        title: String,
        messageTemplate: String,
        priority: Int
    ) -> SmartInsight? {
        guard total > 0 else { return nil }

        let breakdown = Dictionary(grouping: expenses, by: { $0.category.id })
            .compactMap { _, items -> (category: ExpenseCategory, total: Double)? in
                guard let category = items.first?.category else { return nil }
                return (category: category, total: items.reduce(0) { $0 + $1.amount })
            }
            .sorted { $0.total > $1.total }

        guard let top = breakdown.first else { return nil }

        let share = (top.total / total) * 100
        let message = String(format: messageTemplate, top.category.displayName, percentage(share))

        return SmartInsight(
            title: title,
            message: message,
            type: .topCategory,
            priority: priority,
            category: top.category,
            amount: top.total,
            percentChange: share
        )
    }

    private func dailyAverageInsights(
        currentWeekInterval: DateInterval?,
        currentMonthInterval: DateInterval?,
        currentWeekExpenses: [Expense],
        currentMonthExpenses: [Expense],
        calendar: Calendar,
        strings: AppStrings
    ) -> [SmartInsight] {
        var insights: [SmartInsight] = []

        if let currentWeekInterval, !currentWeekExpenses.isEmpty {
            let weekTotal = currentWeekExpenses.reduce(0) { $0 + $1.amount }
            let dayCount = elapsedDays(in: currentWeekInterval, calendar: calendar)
            let average = weekTotal / Double(dayCount)
            insights.append(
                SmartInsight(
                    title: strings.smartInsightsDailyAverageWeekTitle,
                    message: String(format: strings.smartInsightsDailyAverageWeekMessage, currency(average)),
                    type: .dailyAverage,
                    priority: 70,
                    amount: average
                )
            )
        }

        if let currentMonthInterval, !currentMonthExpenses.isEmpty {
            let monthTotal = currentMonthExpenses.reduce(0) { $0 + $1.amount }
            let dayCount = elapsedDays(in: currentMonthInterval, calendar: calendar)
            let average = monthTotal / Double(dayCount)
            insights.append(
                SmartInsight(
                    title: strings.smartInsightsDailyAverageMonthTitle,
                    message: String(format: strings.smartInsightsDailyAverageMonthMessage, currency(average)),
                    type: .dailyAverage,
                    priority: 68,
                    amount: average
                )
            )
        }

        return insights
    }

    private func previousWeekExpenses(from currentWeekInterval: DateInterval?, expenses: [Expense], calendar: Calendar) -> [Expense] {
        guard let currentWeekInterval,
              let previousWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekInterval.start),
              let previousWeekInterval = calendar.dateInterval(of: .weekOfYear, for: previousWeekDate) else {
            return []
        }

        return expenses.filter { previousWeekInterval.contains($0.date) }
    }

    private func expensesForInterval(_ interval: DateInterval?, source expenses: [Expense]) -> [Expense] {
        guard let interval else { return [] }
        return expenses.filter { interval.contains($0.date) }
    }

    private func elapsedDays(in interval: DateInterval, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: interval.start)
        let now = calendar.startOfDay(for: .now)
        let difference = calendar.dateComponents([.day], from: start, to: now).day ?? 0
        return max(difference + 1, 1)
    }

    private func remainingDailyBudget(remaining: Double, cadence: SpendingGoalCadence, calendar: Calendar) -> Double {
        let daysLeft: Double
        switch cadence {
        case .weekly:
            daysLeft = Double(daysLeftInWeek(calendar: calendar))
        case .monthly:
            daysLeft = Double(daysLeftInMonth(calendar: calendar))
        }
        return remaining / max(daysLeft, 1)
    }

    private func projectedSpend(spent: Double, cadence: SpendingGoalCadence, calendar: Calendar) -> Double {
        let elapsedDays: Double
        let totalDays: Double
        switch cadence {
        case .weekly:
            elapsedDays = Double(max(7 - daysLeftInWeek(calendar: calendar), 1))
            totalDays = 7
        case .monthly:
            elapsedDays = Double(max(calendar.component(.day, from: .now), 1))
            totalDays = Double(calendar.range(of: .day, in: .month, for: .now)?.count ?? 30)
        }

        let dailyPace = spent / elapsedDays
        return dailyPace * totalDays
    }

    private func daysLeftInWeek(calendar: Calendar) -> Int {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return 7 }
        let start = calendar.startOfDay(for: .now)
        let end = calendar.startOfDay(for: interval.end)
        let difference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(difference, 1)
    }

    private func daysLeftInMonth(calendar: Calendar) -> Int {
        guard let interval = calendar.dateInterval(of: .month, for: .now) else { return 30 }
        let start = calendar.startOfDay(for: .now)
        let end = calendar.startOfDay(for: interval.end)
        let difference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(difference, 1)
    }

    private func currency(_ amount: Double) -> String {
        String(format: "$%.2f", amount)
    }

    private func percentage(_ value: Double) -> String {
        String(format: "%.0f%%", value)
    }

    private func signedPercent(_ value: Double) -> String {
        String(format: "%+.0f%%", value)
    }
}
