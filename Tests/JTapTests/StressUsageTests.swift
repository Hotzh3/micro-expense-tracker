import XCTest
@testable import JTap

@MainActor
final class StressUsageTests: XCTestCase {
    func testStressGeneratorCreatesExpectedCountsAndValidItems() {
        let generator = DemoDataGenerator(referenceDate: Date(timeIntervalSince1970: 1_700_000_000))

        assertGeneratedExpenses(
            generator.generateExpenses(days: 30, expensesPerDay: 5),
            expectedCount: 150
        )
        assertGeneratedExpenses(
            generator.generateExpenses(days: 60, expensesPerDay: 10),
            expectedCount: 600
        )
        assertGeneratedExpenses(
            generator.generateExpenses(days: 90, expensesPerDay: 20),
            expectedCount: 1_800
        )
        assertGeneratedExpenses(
            generator.generateExpenses(days: 365, expensesPerDay: 10),
            expectedCount: 3_650
        )
    }

    func testViewModelHandlesLargeDatasetAcrossDashboardHistoryGoalsAndBudgets() {
        let generator = DemoDataGenerator(referenceDate: .now)
        let expenses = generator.generateExpenses(days: 365, expensesPerDay: 10)

        let viewModel = ExpenseViewModel()
        viewModel.expenses = expenses
        viewModel.weeklyGoal = SpendingGoal(cadence: .weekly, limit: 750)
        viewModel.monthlyGoal = SpendingGoal(cadence: .monthly, limit: 3_000)
        viewModel.categoryBudgets = [
            CategoryBudget(category: .coffee, cadence: .monthly, limit: 150),
            CategoryBudget(category: .transport, cadence: .monthly, limit: 300)
        ]

        let dashboardSummaries = viewModel.dashboardCategorySummariesSafe
        let trendPoints = viewModel.dashboardTrendPointsSafe
        let topCategory = viewModel.dashboardTopCategorySafe
        let categoryBudgetSignal = viewModel.dashboardCategoryBudgetSignalSafe
        let recurringSignal = viewModel.dashboardRecurringSignalSafe
        let smartInsight = viewModel.dashboardSmartInsightSafe

        XCTAssertEqual(viewModel.expenses.count, 3_650)
        XCTAssertGreaterThan(viewModel.todayTotal, 0)
        XCTAssertGreaterThan(viewModel.weekTotal, 0)
        XCTAssertGreaterThan(viewModel.monthTotal, 0)
        XCTAssertFalse(dashboardSummaries.isEmpty)
        XCTAssertEqual(trendPoints.count, 14)
        XCTAssertNotNil(topCategory)
        XCTAssertNotNil(categoryBudgetSignal)
        XCTAssertNil(recurringSignal)
        XCTAssertNotNil(smartInsight)

        let historyFilter = ExpenseFilter(
            searchText: "OXXO",
            categories: [.convenience],
            dateRange: .month(),
            minAmount: 20,
            maxAmount: 250,
            source: .manual,
            merchant: "OXXO",
            sortOrder: .highest
        )

        let filteredExpenses = viewModel.filteredExpenses(using: historyFilter)

        XCTAssertTrue(filteredExpenses.allSatisfy { expense in
            expense.amount.isFinite
                && expense.amount > 0
                && expense.category == .convenience
                && expense.merchant.localizedCaseInsensitiveContains("OXXO")
                && expense.source == .manual
        })

        XCTAssertTrue(viewModel.goalOverview(for: .weekly)?.spent.isFinite ?? false)
        XCTAssertTrue(viewModel.goalOverview(for: .monthly)?.spent.isFinite ?? false)
        XCTAssertTrue(viewModel.primaryCategoryBudgetOverview?.spent.isFinite ?? false)
    }

    func testLargeBackupExportRoundTripsSafely() {
        let generator = DemoDataGenerator(referenceDate: .now)
        let expenses = generator.generateExpenses(days: 180, expensesPerDay: 30)

        let service = DataBackupService()
        let settings = DataBackupSettingsSnapshot(
            appearance: AppAppearance.dark.rawValue,
            textSize: AppTextSize.medium.rawValue,
            language: AppLanguage.english.rawValue,
            hapticsEnabled: true,
            smartAlertsEnabled: true,
            appLockEnabled: false,
            requireFaceIDOnLaunch: false,
            privacyModeHideAmounts: false,
            hideAmountsInWidgets: false,
            localNotificationsEnabled: false,
            dailyCheckInEnabled: false,
            goalWarningsEnabled: false,
            weeklyDigestReminderEnabled: false,
            dailyCheckInHour: 18,
            dailyCheckInMinute: 0,
            weeklyDigestWeekday: 1,
            weeklyDigestHour: 9,
            weeklyDigestMinute: 0,
            hasSeenOnboarding: true
        )

        let export = service.export(
            expenses: expenses,
            goals: SpendingGoals(
                weekly: SpendingGoal(cadence: .weekly, limit: 1_200),
                monthly: SpendingGoal(cadence: .monthly, limit: 4_800)
            ),
            categoryBudgets: [
                CategoryBudget(category: .coffee, cadence: .monthly, limit: 120),
                CategoryBudget(category: .transport, cadence: .monthly, limit: 300)
            ],
            recurringExpenses: [
                RecurringExpense(
                    merchant: "Netflix",
                    amount: 149,
                    category: .entertainment,
                    cadence: .monthly,
                    nextDueDate: .now
                )
            ],
            settings: settings
        )

        let imported = service.loadBackup(from: Data(export.json.utf8))

        XCTAssertNotNil(imported)
        XCTAssertEqual(imported?.expenses.count, expenses.count)
        XCTAssertEqual(imported?.goals.activeGoals.count, 2)
        XCTAssertEqual(imported?.categoryBudgets.count, 2)
        XCTAssertEqual(imported?.recurringExpenses.count, 1)
        XCTAssertEqual(imported?.settings, settings)
    }

    private func assertGeneratedExpenses(_ expenses: [Expense], expectedCount: Int, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(expenses.count, expectedCount, file: file, line: line)
        XCTAssertEqual(Set(expenses.map(\.id)).count, expectedCount, file: file, line: line)
        XCTAssertTrue(expenses.allSatisfy { $0.amount.isFinite && $0.amount > 0 }, file: file, line: line)
        XCTAssertTrue(expenses.allSatisfy { $0.date.timeIntervalSinceReferenceDate.isFinite }, file: file, line: line)
        XCTAssertTrue(expenses.allSatisfy { ExpenseCategory.allDefaults.contains($0.category) }, file: file, line: line)
        XCTAssertTrue(expenses.allSatisfy { $0.source == .manual || $0.source == .parsedText }, file: file, line: line)
    }
}
