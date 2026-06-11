import Foundation

struct Expense: Identifiable, Equatable, Codable {
    let id: UUID
    var amount: Double
    var category: ExpenseCategory
    var merchant: String
    var note: String
    var date: Date
    var source: ExpenseSource
    var confidence: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        amount: Double,
        category: ExpenseCategory,
        merchant: String = "",
        note: String = "",
        date: Date = .now,
        source: ExpenseSource = .manual,
        confidence: Double = 1.0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.merchant = merchant
        self.note = note
        self.date = date
        self.source = source
        self.confidence = confidence
        self.createdAt = createdAt
    }
}

enum ExpenseSource: String, CaseIterable, Identifiable, Codable {
    case manual
    case parsedText
    case imported
    case demo

    var id: String { rawValue }

    var displayName: String {
        let strings = AppStrings.current()
        switch self {
        case .manual:
            return strings.expenseSourceManual
        case .parsedText:
            return strings.expenseSourceParsedText
        case .imported:
            return strings.expenseSourceImported
        case .demo:
            return strings.expenseSourceDemo
        }
    }
}
