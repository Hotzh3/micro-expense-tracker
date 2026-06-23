import Foundation

struct WeeklyDigestService {
    private let goalIntelligenceService = GoalIntelligenceService()

    func generateDigest(
        expenses: [Expense],
        recurringExpenses: [RecurringExpense],
        goals: SpendingGoals,
        smartInsights: [SmartInsight],
        comparisons: [SpendingComparison],
        calendar: Calendar = .current
    ) -> WeeklyDigest {
        let now = Date.now
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now)
        let weekStart = weekInterval?.start ?? calendar.startOfDay(for: now)
        let weekEnd = weekInterval.map { calendar.date(byAdding: .second, value: -1, to: $0.end) ?? $0.end } ?? now
        let safeExpenses = expenses.filter { $0.amount.isFinite }

        let weeklyExpenses = safeExpenses.filter { expense in
            guard let weekInterval else { return false }
            return weekInterval.contains(expense.date)
        }

        let totalSpend = weeklyExpenses.reduce(0) { $0 + $1.amount }
        let expenseCount = weeklyExpenses.count
        let topCategory = topCategory(from: weeklyExpenses)
        let topMerchant = topMerchant(from: weeklyExpenses)
        let dayTotals = dailyTotals(from: weeklyExpenses, calendar: calendar)
        let highestSpendingDay = dayTotals.max { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key < rhs.key
            }
            return lhs.value < rhs.value
        }?.key
        let highestSpendingDayTotal = highestSpendingDay.flatMap { dayTotals[$0] } ?? 0
        let daysWithExpenses = dayTotals.count
        let totalDaysInWeek = 7
        let daysElapsed = elapsedDays(in: weekInterval, calendar: calendar)
        let averageDailySpend = totalSpend / Double(max(daysElapsed, 1))
        let largestExpense = weeklyExpenses.max(by: { $0.amount < $1.amount })
        let bestInsight = smartInsights.first(where: { $0.type != .neutral }) ?? smartInsights.first
        let goalStatus = weeklyGoalStatus(goals: goals, expenses: expenses, calendar: calendar)
        let comparisonVsLastWeek = comparisons.first(where: { $0.period == .weekVsLastWeek })
        let summaryText = summaryText(
            totalSpend: totalSpend,
            topCategory: topCategory,
            highestSpendingDay: highestSpendingDay,
            daysWithExpenses: daysWithExpenses,
            totalDaysInWeek: totalDaysInWeek,
            language: AppLanguage.current
        )
        let highlightTexts = highlightTexts(
            totalSpend: totalSpend,
            topCategory: topCategory,
            topMerchant: topMerchant,
            highestSpendingDay: highestSpendingDay,
            highestSpendingDayTotal: highestSpendingDayTotal,
            averageDailySpend: averageDailySpend,
            goalStatus: goalStatus,
            recurringExpenses: recurringExpenses,
            calendar: calendar
        )

        return WeeklyDigest(
            weekStart: weekStart,
            weekEnd: weekEnd,
            totalSpend: totalSpend,
            expenseCount: expenseCount,
            topCategory: topCategory,
            topMerchant: topMerchant,
            highestSpendingDay: highestSpendingDay,
            daysWithExpenses: daysWithExpenses,
            totalDaysInWeek: totalDaysInWeek,
            averageDailySpend: averageDailySpend,
            largestExpense: largestExpense,
            bestInsight: bestInsight,
            goalStatus: goalStatus,
            comparisonVsLastWeek: comparisonVsLastWeek,
            summaryText: summaryText,
            highlightTexts: highlightTexts
        )
    }

    private func topCategory(from expenses: [Expense]) -> ExpenseCategory? {
        let grouped = Dictionary(grouping: expenses.filter { $0.amount.isFinite }, by: { $0.category.id })
        let breakdown = grouped.compactMap { _, items -> (category: ExpenseCategory, total: Double)? in
            guard let category = items.first?.category else { return nil }
            return (category: category, total: items.reduce(0) { $0 + $1.amount })
        }

        return breakdown.sorted { $0.total > $1.total }.first?.category
    }

    private func topMerchant(from expenses: [Expense]) -> String? {
        let grouped = Dictionary(grouping: expenses.filter { $0.amount.isFinite }, by: { expense -> String in
            let merchant = expense.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
            return merchant.isEmpty ? expense.category.displayName : merchant
        })

        return grouped.compactMap { merchant, items -> (merchant: String, total: Double)? in
            let total = items.reduce(0) { $0 + $1.amount }
            guard total.isFinite, total > 0 else { return nil }
            return (merchant: merchant, total: total)
        }
        .sorted { lhs, rhs in
            if lhs.total == rhs.total {
                return lhs.merchant.localizedCaseInsensitiveCompare(rhs.merchant) == .orderedAscending
            }
            return lhs.total > rhs.total
        }
        .first?.merchant
    }

    private func dailyTotals(from expenses: [Expense], calendar: Calendar) -> [Date: Double] {
        Dictionary(grouping: expenses.filter { $0.amount.isFinite }, by: { calendar.startOfDay(for: $0.date) })
            .mapValues { items in
                items.reduce(0) { $0 + $1.amount }
            }
    }

    private func elapsedDays(in interval: DateInterval?, calendar: Calendar) -> Int {
        guard let interval else { return 1 }
        let start = calendar.startOfDay(for: interval.start)
        let now = calendar.startOfDay(for: .now)
        let difference = calendar.dateComponents([.day], from: start, to: now).day ?? 0
        return max(difference + 1, 1)
    }

    private func weeklyGoalStatus(
        goals: SpendingGoals,
        expenses: [Expense],
        calendar: Calendar
    ) -> GoalForecastStatus? {
        if let weeklyGoal = goals.weekly,
           let forecast = goalIntelligenceService.forecast(for: weeklyGoal, expenses: expenses.filter { $0.amount.isFinite }, calendar: calendar) {
            return forecast.status
        }

        if let monthlyGoal = goals.monthly,
           let forecast = goalIntelligenceService.forecast(for: monthlyGoal, expenses: expenses.filter { $0.amount.isFinite }, calendar: calendar) {
            return forecast.status
        }

        return nil
    }

    private func summaryText(
        totalSpend: Double,
        topCategory: ExpenseCategory?,
        highestSpendingDay: Date?,
        daysWithExpenses: Int,
        totalDaysInWeek: Int,
        language: AppLanguage
    ) -> String {
        let totalText = String(format: "$%.2f", totalSpend)
        let categoryText = topCategory?.displayName ?? "your tracked spending"
        let dayText = highestSpendingDay?.formatted(date: .complete, time: .omitted) ?? (language == .english ? "this week" : "esta semana")

        switch language {
        case .english:
            return "This week you spent \(totalText). Your top category was \(categoryText). \(dayText) was your highest spending day. You logged expenses on \(daysWithExpenses) of \(totalDaysInWeek) days."
        case .spanish:
            return "Esta semana gastaste \(totalText). Tu categoría principal fue \(categoryText). \(dayText) fue tu día de mayor gasto. Registraste gastos en \(daysWithExpenses) de \(totalDaysInWeek) días."
        }
    }

    private func highlightTexts(
        totalSpend: Double,
        topCategory: ExpenseCategory?,
        topMerchant: String?,
        highestSpendingDay: Date?,
        highestSpendingDayTotal: Double,
        averageDailySpend: Double,
        goalStatus: GoalForecastStatus?,
        recurringExpenses: [RecurringExpense],
        calendar: Calendar
    ) -> [String] {
        var highlights: [String] = []
        let merchantText = topMerchant ?? (AppLanguage.current == .english ? "No merchant yet" : "Aún no hay comercio")

        if let goalStatus, goalStatus != .safe {
            switch AppLanguage.current {
            case .english:
                highlights.append(goalStatus == .over ? "Near or above your limit." : "You are getting close to your limit.")
            case .spanish:
                highlights.append(goalStatus == .over ? "Cerca o por encima de tu límite." : "Te estás acercando a tu límite.")
            }
        }

        if let topCategory {
            switch AppLanguage.current {
            case .english:
                highlights.append("Category focus: \(topCategory.displayName).")
            case .spanish:
                highlights.append("Categoría principal: \(topCategory.displayName).")
            }
        }

        if let highestSpendingDay {
            let grouped = Dictionary(
                grouping: recurringExpenses.filter { $0.isValid },
                by: { calendar.startOfDay(for: $0.nextDueDate) }
            )
            let recurringCount = grouped[calendar.startOfDay(for: highestSpendingDay)]?.count ?? 0
            let baseline = averageDailySpend
            if baseline > 0, highestSpendingDayTotal > baseline * 1.5 {
                highlights.append(AppLanguage.current == .english ? "Unusual spending spike this week." : "Pico de gasto inusual esta semana.")
            }
            if recurringCount > 0 {
                highlights.append(AppLanguage.current == .english ? "Recurring expenses land near your busiest day." : "Los gastos recurrentes caen cerca de tu día más cargado.")
            }
        }

        if recurringExpenses.contains(where: { $0.isValid && $0.isActive }) {
            highlights.append(AppLanguage.current == .english ? "Recurring expenses detected." : "Se detectaron gastos recurrentes.")
        }

        if !highlights.contains(where: { $0.localizedCaseInsensitiveContains(merchantText) }) {
            highlights.append(AppLanguage.current == .english ? "Top merchant: \(merchantText)." : "Comercio principal: \(merchantText).")
        }

        return Array(highlights.prefix(4))
    }
}
