import Foundation

enum RecurringExpenseCadence: String, CaseIterable, Identifiable, Codable {
    case daily
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    func advanced(from date: Date, calendar: Calendar = .current) -> Date? {
        let component: Calendar.Component
        let value: Int

        switch self {
        case .daily:
            component = .day
            value = 1
        case .weekly:
            component = .weekOfYear
            value = 1
        case .monthly:
            component = .month
            value = 1
        case .yearly:
            component = .year
            value = 1
        }

        return calendar.date(byAdding: component, value: value, to: date)
    }
}

struct RecurringExpense: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var merchant: String
    var amount: Double
    var category: ExpenseCategory
    var cadence: RecurringExpenseCadence
    var nextDueDate: Date
    var isActive: Bool = true
    var createdAt: Date = .now
    var updatedAt: Date = .now

    var isValid: Bool {
        amount.isFinite
            && amount > 0
            && nextDueDate.timeIntervalSinceReferenceDate.isFinite
            && createdAt.timeIntervalSinceReferenceDate.isFinite
            && updatedAt.timeIntervalSinceReferenceDate.isFinite
            && !category.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var normalizedMerchant: String {
        merchant.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func nextOccurrence(after date: Date, calendar: Calendar = .current) -> Date? {
        cadence.advanced(from: date, calendar: calendar)
    }

    func nextOccurrenceFromStoredDate(calendar: Calendar = .current) -> Date? {
        cadence.advanced(from: nextDueDate, calendar: calendar)
    }
}
