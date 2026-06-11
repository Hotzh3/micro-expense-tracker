import XCTest
@testable import JTap

@MainActor
final class CategoryBudgetTests: XCTestCase {
    func testCategoryBudgetIsValidForFinitePositiveLimit() {
        let budget = CategoryBudget(category: .coffee, cadence: .monthly, limit: 100)

        XCTAssertTrue(budget.isValid)
        XCTAssertEqual(budget.storageKey.contains(budget.category.id.uuidString), true)
    }

    func testCategoryBudgetOverviewTracksSpentAndStatus() {
        let viewModel = ExpenseViewModel()
        viewModel.expenses = [
            Expense(amount: 40, category: .coffee, date: .now),
            Expense(amount: 30, category: .coffee, date: .now)
        ]
        let budget = CategoryBudget(category: .coffee, cadence: .monthly, limit: 100)
        viewModel.categoryBudgets = [budget]

        let overview = viewModel.primaryCategoryBudgetOverview

        XCTAssertNotNil(overview)
        XCTAssertEqual(overview?.spent, 70, accuracy: 0.01)
        XCTAssertEqual(overview?.remaining, 30, accuracy: 0.01)
        XCTAssertEqual(overview?.percentUsed, 70, accuracy: 0.01)
        XCTAssertEqual(overview?.status, .safe)
    }
}
