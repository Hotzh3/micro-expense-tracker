import Foundation

struct ExpenseDateRange: Equatable {
    var startDate: Date?
    var endDate: Date?

    static let all = ExpenseDateRange(startDate: nil, endDate: nil)

    static func today(calendar: Calendar = .current) -> ExpenseDateRange {
        guard let interval = calendar.dateInterval(of: .day, for: .now) else { return .all }
        return ExpenseDateRange(startDate: interval.start, endDate: interval.end)
    }

    static func week(calendar: Calendar = .current) -> ExpenseDateRange {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return .all }
        return ExpenseDateRange(startDate: interval.start, endDate: interval.end)
    }

    static func month(calendar: Calendar = .current) -> ExpenseDateRange {
        guard let interval = calendar.dateInterval(of: .month, for: .now) else { return .all }
        return ExpenseDateRange(startDate: interval.start, endDate: interval.end)
    }

    static func custom(start: Date?, end: Date?) -> ExpenseDateRange {
        ExpenseDateRange(startDate: start, endDate: end)
    }

    var isAll: Bool {
        startDate == nil && endDate == nil
    }

    var signature: String {
        [
            startDate?.timeIntervalSinceReferenceDate.description ?? "nil",
            endDate?.timeIntervalSinceReferenceDate.description ?? "nil"
        ]
        .joined(separator: "-")
    }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        if let startDate, date < startDate {
            return false
        }

        if let endDate, date >= endDate {
            return false
        }

        return true
    }
}

enum ExpenseFilterSortOrder: String, CaseIterable, Identifiable, Codable {
    case newest
    case highest
    case lowest
    case category

    var id: String { rawValue }

    var title: String {
        let strings = AppStrings.current()
        switch self {
        case .newest:
            return strings.historySortNewest
        case .highest:
            return strings.historySortHighest
        case .lowest:
            return strings.historySortLowest
        case .category:
            return strings.historySortCategory
        }
    }

    func sorted(_ expenses: [Expense]) -> [Expense] {
        switch self {
        case .newest:
            return expenses.sorted { $0.date > $1.date }
        case .highest:
            return expenses.sorted {
                if $0.amount == $1.amount {
                    return $0.date > $1.date
                }
                return $0.amount > $1.amount
            }
        case .lowest:
            return expenses.sorted {
                if $0.amount == $1.amount {
                    return $0.date > $1.date
                }
                return $0.amount < $1.amount
            }
        case .category:
            return expenses.sorted {
                if $0.category.displayName == $1.category.displayName {
                    return $0.date > $1.date
                }
                return $0.category.displayName.localizedCaseInsensitiveCompare($1.category.displayName) == .orderedAscending
            }
        }
    }
}

struct ExpenseFilter: Equatable {
    var searchText: String = ""
    var categories: Set<ExpenseCategory> = []
    var dateRange: ExpenseDateRange = .all
    var minAmount: Double?
    var maxAmount: Double?
    var source: ExpenseSource?
    var merchant: String = ""
    var sortOrder: ExpenseFilterSortOrder = .newest

    var isActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !categories.isEmpty
            || !dateRange.isAll
            || minAmount != nil
            || maxAmount != nil
            || source != nil
            || !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || sortOrder != .newest
    }

    var signature: String {
        let categorySignature = categories
            .map { $0.id.uuidString }
            .sorted()
            .joined(separator: ",")

        let merchantSignature = merchant.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return [
            searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            categorySignature,
            dateRange.signature,
            minAmount.map { String(format: "%.2f", $0) } ?? "nil",
            maxAmount.map { String(format: "%.2f", $0) } ?? "nil",
            source?.rawValue ?? "nil",
            merchantSignature,
            sortOrder.rawValue
        ]
        .joined(separator: "|")
    }

    func matches(_ expense: Expense, calendar: Calendar = .current) -> Bool {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let expenseMerchant = expense.merchant.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let categoryName = expense.category.displayName.lowercased()
        let note = expense.note.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if !normalizedSearch.isEmpty {
            let searchable = [
                expenseMerchant,
                categoryName,
                note,
                expense.source.rawValue.lowercased()
            ].joined(separator: " ")

            guard searchable.contains(normalizedSearch) else { return false }
        }

        if !categories.isEmpty, !categories.contains(expense.category) {
            return false
        }

        if !dateRange.contains(expense.date, calendar: calendar) {
            return false
        }

        if let minAmount, expense.amount < minAmount {
            return false
        }

        if let maxAmount, expense.amount > maxAmount {
            return false
        }

        if let source, expense.source != source {
            return false
        }

        if !normalizedMerchant.isEmpty, !expenseMerchant.contains(normalizedMerchant) {
            return false
        }

        return true
    }

    func normalizedMerchantMatches(_ value: String) -> Bool {
        let query = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty { return true }
        return merchant.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().contains(query)
    }

    func settingDateRange(_ range: ExpenseDateRange) -> ExpenseFilter {
        var copy = self
        copy.dateRange = range
        return copy
    }
}
