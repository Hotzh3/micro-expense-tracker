import SwiftUI

@MainActor
final class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense]
    @Published var selectedCategory: ExpenseCategory
    @Published var amountText: String = ""
    @Published var merchantText: String = ""
    @Published var noteText: String = ""

    let categories: [ExpenseCategory]
    private let store: ExpenseStore

    init(store: ExpenseStore = ExpenseStore()) {
        self.store = store
        self.expenses = store.sampleExpenses()
        self.categories = ExpenseCategory.allDefaults
        self.selectedCategory = ExpenseCategory.allDefaults.first ?? .other
    }

    func saveDraftExpense() {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")), amount > 0 else { return }

        let expense = Expense(
            amount: amount,
            category: selectedCategory,
            merchant: merchantText,
            note: noteText,
            source: .manual,
            confidence: 1.0
        )

        expenses.insert(expense, at: 0)
        amountText = ""
        merchantText = ""
        noteText = ""
    }

    var todayTotal: Double {
        expenses
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    var weekTotal: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var monthTotal: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var topCategory: ExpenseCategory {
        let grouped = Dictionary(grouping: expenses, by: { $0.category.displayName })
        let bestName = grouped.max(by: { $0.value.count < $1.value.count })?.key
        return categories.first(where: { $0.displayName == bestName }) ?? categories.last ?? .other
    }
}
