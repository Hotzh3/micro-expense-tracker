import Foundation

struct GoalIntelligenceService {
    func generateForecasts(
        expenses: [Expense],
        goals: SpendingGoals,
        calendar: Calendar = .current
    ) -> [GoalForecast] {
        let safeExpenses = expenses.filter { $0.amount.isFinite }
        let activeGoals: [SpendingGoal] = [goals.weekly, goals.monthly].compactMap { $0 }
        return activeGoals.compactMap { goal in
            forecast(for: goal, expenses: safeExpenses, calendar: calendar)
        }
    }

    func forecast(
        for goal: SpendingGoal,
        expenses: [Expense],
        calendar: Calendar = .current
    ) -> GoalForecast? {
        guard goal.limit.isFinite, goal.limit > 0 else { return nil }
        let safeExpenses = expenses.filter { $0.amount.isFinite }

        let interval: DateInterval?
        switch goal.cadence {
        case .weekly:
            interval = calendar.dateInterval(of: .weekOfYear, for: .now)
        case .monthly:
            interval = calendar.dateInterval(of: .month, for: .now)
        }

        guard let interval else { return nil }

        let filteredExpenses = safeExpenses.filter { interval.contains($0.date) }
        let spent = filteredExpenses.reduce(0) { $0 + $1.amount }
        guard spent.isFinite else { return nil }
        let limit = goal.limit
        let remaining = max(limit - spent, 0)

        let start = calendar.startOfDay(for: interval.start)
        let end = calendar.startOfDay(for: interval.end)
        let totalDays = max(calendar.dateComponents([.day], from: start, to: end).day ?? 0, 1)
        let currentDay = calendar.startOfDay(for: .now)
        let elapsedDays = (calendar.dateComponents([.day], from: start, to: currentDay).day ?? 0) + 1
        let elapsed = max(elapsedDays, 1)
        let daysElapsed = min(elapsed, totalDays)
        let daysRemaining = max(totalDays - daysElapsed, 0)
        let averageDailySpend = spent / Double(daysElapsed)
        let remainingDailyBudget = remaining / Double(max(daysRemaining, 1))
        let projectedSpend = averageDailySpend * Double(totalDays)
        let projectedOverLimitAmount = max(projectedSpend - limit, 0)
        guard [
            spent,
            remaining,
            averageDailySpend,
            remainingDailyBudget,
            projectedSpend,
            projectedOverLimitAmount
        ].allSatisfy({ $0.isFinite }) else {
            return nil
        }
        let status = forecastStatus(
            spent: spent,
            limit: limit,
            projectedSpend: projectedSpend,
            projectedOverLimitAmount: projectedOverLimitAmount
        )

        return GoalForecast(
            goalType: goal.cadence,
            limit: limit,
            spent: spent,
            remaining: remaining,
            daysElapsed: daysElapsed,
            daysRemaining: daysRemaining,
            averageDailySpend: averageDailySpend,
            remainingDailyBudget: remainingDailyBudget,
            projectedSpend: projectedSpend,
            projectedOverLimitAmount: projectedOverLimitAmount,
            status: status
        )
    }

    private func forecastStatus(
        spent: Double,
        limit: Double,
        projectedSpend: Double,
        projectedOverLimitAmount: Double
    ) -> GoalForecastStatus {
        if spent >= limit {
            return .over
        }

        let projectedRatio = projectedSpend / max(limit, 1)
        guard projectedRatio.isFinite else { return .over }

        if projectedRatio < 0.85 {
            return .safe
        }

        if projectedRatio < 1.0 {
            return .watch
        }

        if projectedOverLimitAmount <= limit * 0.15 {
            return .risk
        }

        return .over
    }
}
