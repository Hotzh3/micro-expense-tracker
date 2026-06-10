import XCTest
@testable import JTap

final class CrashSafetyTests: XCTestCase {
    func testGoalForecastIgnoresInvalidGoalLimit() {
        let goal = SpendingGoal(cadence: .weekly, limit: 0)
        let service = GoalIntelligenceService()

        let forecasts = service.generateForecasts(
            expenses: [Expense(amount: 20, category: .food, date: .now)],
            goals: SpendingGoals(weekly: goal, monthly: nil)
        )

        XCTAssertTrue(forecasts.isEmpty)
    }

    func testGoalForecastUsesOnlyFiniteExpenses() {
        let goal = SpendingGoal(cadence: .weekly, limit: 100)
        let expenses = [
            Expense(amount: .nan, category: .food, date: .now),
            Expense(amount: 20, category: .food, date: .now)
        ]

        let forecast = GoalIntelligenceService().forecast(
            for: goal,
            expenses: expenses,
            calendar: .current
        )

        XCTAssertNotNil(forecast)
        XCTAssertEqual(forecast?.spent ?? -1, 20, accuracy: 0.01)
        XCTAssertTrue(forecast?.spent.isFinite ?? false)
        XCTAssertTrue(forecast?.projectedSpend.isFinite ?? false)
    }

    func testComparisonsIgnoreNonFiniteExpenses() {
        let service = SpendingComparisonService()
        let expenses = [
            Expense(amount: .nan, category: .coffee, date: .now),
            Expense(amount: 12, category: .coffee, date: .now)
        ]

        let comparisons = service.generateComparisons(
            expenses: expenses,
            calendar: .current,
            strings: AppStrings.current()
        )

        XCTAssertTrue(comparisons.allSatisfy { $0.currentAmount.isFinite && $0.previousAmount.isFinite })
    }
}
