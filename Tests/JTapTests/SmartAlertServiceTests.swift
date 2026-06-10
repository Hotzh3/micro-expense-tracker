import XCTest
@testable import JTap

final class SmartAlertServiceTests: XCTestCase {
    private let service = SmartAlertService()

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: AppPreferenceKeys.smartAlertsEnabled)
        UserDefaults.standard.removeObject(forKey: AppPreferenceKeys.dismissedSmartAlertIDs)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: AppPreferenceKeys.smartAlertsEnabled)
        UserDefaults.standard.removeObject(forKey: AppPreferenceKeys.dismissedSmartAlertIDs)
        super.tearDown()
    }

    func testGeneratesNoDataAlertWhenThereAreNoExpenses() {
        let alerts = service.generateAlerts(
            expenses: [],
            goalForecasts: [],
            comparisons: [],
            strings: AppStrings.current()
        )

        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts.first?.type, .noData)
        XCTAssertEqual(alerts.first?.severity, .info)
    }

    func testDismissedAlertDoesNotReappearImmediately() {
        let goal = SpendingGoal(cadence: .weekly, limit: 10)
        let expenses = [Expense(amount: 25, category: .food, date: .now)]
        let forecasts = GoalIntelligenceService().generateForecasts(
            expenses: expenses,
            goals: SpendingGoals(weekly: goal, monthly: nil)
        )

        let alerts = service.generateAlerts(
            expenses: expenses,
            goalForecasts: forecasts,
            comparisons: [],
            strings: AppStrings.current()
        )

        XCTAssertEqual(alerts.first?.type, .goalRisk)

        if let alert = alerts.first {
            service.dismissAlert(id: alert.id)
        }

        let dismissed = service.generateAlerts(
            expenses: expenses,
            goalForecasts: forecasts,
            comparisons: [],
            strings: AppStrings.current()
        )

        XCTAssertTrue(dismissed.isEmpty)
    }

    func testSmartAlertsToggleDisablesAlerts() {
        UserDefaults.standard.set(false, forKey: AppPreferenceKeys.smartAlertsEnabled)

        let alerts = service.generateAlerts(
            expenses: [],
            goalForecasts: [],
            comparisons: [],
            strings: AppStrings.current()
        )

        XCTAssertTrue(alerts.isEmpty)
    }
}
