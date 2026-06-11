import XCTest
@testable import JTap

@MainActor
final class DashboardStabilityTests: XCTestCase {
    func testDashboardCategorySharesHandleRepeatedCategories() {
        let viewModel = ExpenseViewModel()
        viewModel.expenses = [
            Expense(amount: 12, category: .coffee, merchant: "Cafe A", date: .now),
            Expense(amount: 8, category: .coffee, merchant: "Cafe B", date: .now),
            Expense(amount: 20, category: .food, merchant: "Lunch", date: .now),
            Expense(amount: 0, category: .food, merchant: "Zero", date: .now)
        ]

        let shares = viewModel.categorySharesThisMonth
        let summaries = viewModel.dashboardCategorySummariesSafe

        XCTAssertEqual(shares.count, 2)
        XCTAssertTrue(shares.allSatisfy { $0.percentage.isFinite })

        let percentSum = shares.reduce(0) { $0 + $1.percentage }
        XCTAssertEqual(percentSum, 100, accuracy: 0.01)

        XCTAssertEqual(summaries.count, 2)
        XCTAssertTrue(summaries.allSatisfy { $0.percentage.isFinite })
        XCTAssertTrue(summaries.allSatisfy { $0.id.isEmpty == false })
    }

    func testDashboardRecentTrendAlwaysReturnsStableWindow() {
        let viewModel = ExpenseViewModel()
        viewModel.expenses = [
            Expense(amount: 15, category: .transport, date: .now),
            Expense(amount: 22, category: .shopping, date: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now),
            Expense(amount: 5, category: .entertainment, date: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now)
        ]

        let points = viewModel.recentSpendTrendData
        let dashboardPoints = viewModel.dashboardTrendPointsSafe

        XCTAssertEqual(points.count, 14)
        XCTAssertTrue(points.allSatisfy { $0.total.isFinite })
        XCTAssertTrue(points.allSatisfy { $0.total >= 0 })
        XCTAssertEqual(dashboardPoints.count, 14)
        XCTAssertTrue(dashboardPoints.allSatisfy { $0.total.isFinite })
        XCTAssertTrue(dashboardPoints.allSatisfy { $0.total >= 0 })
    }

    func testDashboardSafeHelpersIgnoreInvalidAmounts() {
        let viewModel = ExpenseViewModel()
        viewModel.expenses = [
            Expense(amount: .nan, category: .coffee, date: .now),
            Expense(amount: -.infinity, category: .food, date: .now),
            Expense(amount: 0, category: .transport, date: .now)
        ]

        XCTAssertTrue(viewModel.dashboardCategorySummariesSafe.isEmpty)
        XCTAssertNil(viewModel.dashboardTopCategorySafe)
        XCTAssertTrue(viewModel.dashboardTrendPointsSafe.allSatisfy { $0.total.isFinite })
    }
}
