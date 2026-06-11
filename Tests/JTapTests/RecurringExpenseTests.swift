import XCTest
@testable import JTap

final class RecurringExpenseTests: XCTestCase {
    func testRecurringExpenseIsValidForFinitePositiveAmount() {
        let recurring = RecurringExpense(
            merchant: "Netflix",
            amount: 149.0,
            category: .entertainment,
            cadence: .monthly,
            nextDueDate: .now
        )

        XCTAssertTrue(recurring.isValid)
        XCTAssertEqual(recurring.normalizedMerchant, "Netflix")
    }

    func testRecurringExpenseCadenceAdvancesForward() {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let recurring = RecurringExpense(
            merchant: "Spotify",
            amount: 129.0,
            category: .entertainment,
            cadence: .monthly,
            nextDueDate: date
        )

        let next = recurring.nextOccurrenceFromStoredDate(calendar: calendar)

        XCTAssertNotNil(next)
        XCTAssertGreaterThan(next ?? date, date)
    }

    func testRecurringExpenseStoreDropsInvalidEntries() {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("recurring.json")
        let store = RecurringExpenseStore(fileURL: fileURL)

        let valid = RecurringExpense(
            merchant: "Rent",
            amount: 1200,
            category: .other,
            cadence: .monthly,
            nextDueDate: .now
        )
        let invalid = RecurringExpense(
            merchant: "Broken",
            amount: 0,
            category: .other,
            cadence: .monthly,
            nextDueDate: .now
        )

        store.saveRecurringExpenses([valid, invalid])
        let loaded = store.loadRecurringExpenses()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.merchant, "Rent")
        XCTAssertTrue(loaded.first?.isValid ?? false)
    }
}
