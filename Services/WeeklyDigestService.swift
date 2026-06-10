import Foundation

struct WeeklyDigestService {
    private let goalIntelligenceService = GoalIntelligenceService()

    func generateDigest(
        expenses: [Expense],
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
        let daysElapsed = elapsedDays(in: weekInterval, calendar: calendar)
        let averageDailySpend = totalSpend / Double(max(daysElapsed, 1))
        let largestExpense = weeklyExpenses.max(by: { $0.amount < $1.amount })
        let bestInsight = smartInsights.first(where: { $0.type != .neutral }) ?? smartInsights.first
        let goalStatus = weeklyGoalStatus(goals: goals, expenses: expenses, calendar: calendar)
        let comparisonVsLastWeek = comparisons.first(where: { $0.period == .weekVsLastWeek })

        return WeeklyDigest(
            weekStart: weekStart,
            weekEnd: weekEnd,
            totalSpend: totalSpend,
            expenseCount: expenseCount,
            topCategory: topCategory,
            averageDailySpend: averageDailySpend,
            largestExpense: largestExpense,
            bestInsight: bestInsight,
            goalStatus: goalStatus,
            comparisonVsLastWeek: comparisonVsLastWeek
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
}
