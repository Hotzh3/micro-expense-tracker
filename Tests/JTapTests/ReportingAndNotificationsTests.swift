import XCTest
@testable import JTap

@MainActor
final class ReportingAndNotificationsTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: AppPreferenceKeys.localNotificationsEnabled)
        UserDefaults.standard.removeObject(forKey: AppPreferenceKeys.dailyCheckInEnabled)
        UserDefaults.standard.removeObject(forKey: AppPreferenceKeys.goalWarningsEnabled)
        UserDefaults.standard.removeObject(forKey: "app.localNotifications.budgetAlert.lastPeriod.weekly")
        UserDefaults.standard.removeObject(forKey: "app.localNotifications.budgetAlert.lastPeriod.monthly")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: AppPreferenceKeys.localNotificationsEnabled)
        UserDefaults.standard.removeObject(forKey: AppPreferenceKeys.dailyCheckInEnabled)
        UserDefaults.standard.removeObject(forKey: AppPreferenceKeys.goalWarningsEnabled)
        UserDefaults.standard.removeObject(forKey: "app.localNotifications.budgetAlert.lastPeriod.weekly")
        UserDefaults.standard.removeObject(forKey: "app.localNotifications.budgetAlert.lastPeriod.monthly")
        super.tearDown()
    }

    func testBudgetAlertCandidatesQualifyAtEightyPercentWeekly() {
        let service = LocalNotificationService.shared
        let goal = SpendingGoal(cadence: .weekly, limit: 100)
        let forecasts = GoalIntelligenceService().generateForecasts(
            expenses: [
                Expense(amount: 80, category: .food, date: .now)
            ],
            goals: SpendingGoals(weekly: goal, monthly: nil)
        )

        let candidates = service.budgetAlertCandidates(from: forecasts)

        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates.first?.cadence, .weekly)
        XCTAssertGreaterThanOrEqual(candidates.first?.percentUsed ?? 0, 80)
    }

    func testBudgetAlertCandidatesQualifyAtEightyPercentMonthly() {
        let service = LocalNotificationService.shared
        let goal = SpendingGoal(cadence: .monthly, limit: 200)
        let forecasts = GoalIntelligenceService().generateForecasts(
            expenses: [
                Expense(amount: 160, category: .shopping, date: .now)
            ],
            goals: SpendingGoals(weekly: nil, monthly: goal)
        )

        let candidates = service.budgetAlertCandidates(from: forecasts)

        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates.first?.cadence, .monthly)
        XCTAssertGreaterThanOrEqual(candidates.first?.percentUsed ?? 0, 80)
    }

    func testBudgetAlertCandidatesSkipBelowThreshold() {
        let service = LocalNotificationService.shared
        let goal = SpendingGoal(cadence: .weekly, limit: 100)
        let forecasts = GoalIntelligenceService().generateForecasts(
            expenses: [
                Expense(amount: 79, category: .food, date: .now)
            ],
            goals: SpendingGoals(weekly: goal, monthly: nil)
        )

        let candidates = service.budgetAlertCandidates(from: forecasts)

        XCTAssertTrue(candidates.isEmpty)
    }

    func testBudgetAlertDedupesPerPeriodKey() {
        let service = LocalNotificationService.shared
        let goal = SpendingGoal(cadence: .weekly, limit: 100)
        let forecasts = GoalIntelligenceService().generateForecasts(
            expenses: [
                Expense(amount: 85, category: .food, date: .now)
            ],
            goals: SpendingGoals(weekly: goal, monthly: nil)
        )

        guard let candidate = service.budgetAlertCandidates(from: forecasts).first else {
            return XCTFail("Expected a budget alert candidate")
        }

        UserDefaults.standard.set(candidate.periodKey, forKey: "app.localNotifications.budgetAlert.lastPeriod.weekly")

        XCTAssertFalse(service.shouldScheduleBudgetAlert(candidate))
    }

    func testWeeklyDigestIncludesTopMerchantAndHighlights() {
        let service = WeeklyDigestService()
        let now = Date.now
        let digest = service.generateDigest(
            expenses: [
                Expense(amount: 50, category: .food, merchant: "Cafe One", date: now),
                Expense(amount: 75, category: .shopping, merchant: "Store Two", date: now),
                Expense(amount: 25, category: .shopping, merchant: "Store Two", date: now.addingTimeInterval(-86_400))
            ],
            recurringExpenses: [
                RecurringExpense(merchant: "Spotify", amount: 129, category: .entertainment, cadence: .monthly, nextDueDate: now)
            ],
            goals: SpendingGoals(weekly: SpendingGoal(cadence: .weekly, limit: 100)),
            smartInsights: [],
            comparisons: []
        )

        XCTAssertEqual(digest.topMerchant, "Store Two")
        XCTAssertGreaterThan(digest.daysWithExpenses, 0)
        XCTAssertFalse(digest.summaryText.isEmpty)
        XCTAssertFalse(digest.highlightTexts.isEmpty)
    }

    func testCalendarMonthReviewGroupsExpensesByDay() {
        let viewModel = ExpenseViewModel()
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)) ?? calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        viewModel.expenses = [
            Expense(amount: 20, category: .coffee, merchant: "Cafe", date: today),
            Expense(amount: 40, category: .food, merchant: "Lunch", date: today),
            Expense(amount: 15, category: .transport, merchant: "Taxi", date: yesterday)
        ]

        let monthReview = viewModel.calendarMonthReview
        let todayReview = viewModel.calendarDayReview(for: today)

        XCTAssertGreaterThanOrEqual(monthReview.daysWithExpenses, 2)
        XCTAssertEqual(todayReview.expenses.count, 2)
        XCTAssertEqual(todayReview.total, 60, accuracy: 0.01)
        XCTAssertFalse(todayReview.categoryBreakdown.isEmpty)
        XCTAssertNotNil(todayReview.topMerchant)
    }
}
