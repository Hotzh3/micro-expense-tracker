import SwiftUI

@MainActor
final class ExpenseViewModel: ObservableObject {
    struct Feedback: Equatable {
        let message: String
        let isError: Bool
    }

    @Published var expenses: [Expense]
    @Published var selectedCategory: ExpenseCategory
    @Published var amountText: String = ""
    @Published var merchantText: String = ""
    @Published var noteText: String = ""
    @Published var saveFeedback: Feedback?

    let categories: [ExpenseCategory]
    private let calendar: Calendar

    init(store: ExpenseStore = ExpenseStore()) {
        self.expenses = store.sampleExpenses()
        self.categories = ExpenseCategory.allDefaults
        self.selectedCategory = ExpenseCategory.allDefaults.first ?? .other
        self.calendar = .current
    }

    func saveDraftExpense() {
        let sanitizedAmount = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(sanitizedAmount.replacingOccurrences(of: ",", with: ".")), amount > 0 else {
            showFeedback(message: "Enter a valid amount.", isError: true)
            return
        }

        let expense = Expense(
            amount: amount,
            category: selectedCategory,
            merchant: merchantText.trimmingCharacters(in: .whitespacesAndNewlines),
            note: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
            source: .manual,
            confidence: 1.0
        )

        expenses.insert(expense, at: 0)
        amountText = ""
        merchantText = ""
        noteText = ""
        selectedCategory = categories.first ?? .other
        showFeedback(message: "Expense saved.", isError: false)
    }

    func deleteExpense(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
    }

    func clearSaveFeedback() {
        saveFeedback = nil
    }

    var todayTotal: Double {
        expenses
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    var weekTotal: Double {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return 0 }
        return expenses
            .filter { weekInterval.contains($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    var monthTotal: Double {
        guard let monthInterval = calendar.dateInterval(of: .month, for: .now) else { return 0 }
        return expenses
            .filter { monthInterval.contains($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    var topCategory: ExpenseCategory? {
        let grouped = Dictionary(grouping: expenses, by: { $0.category.id })
        guard let bestCategoryID = grouped.max(by: { $0.value.count < $1.value.count })?.key else { return nil }
        return expenses.first(where: { $0.category.id == bestCategoryID })?.category
    }

    var averageDailySpend: Double {
        guard let firstExpenseDate = expenses.map(\.date).min() else { return 0 }
        let start = calendar.startOfDay(for: firstExpenseDate)
        let end = calendar.startOfDay(for: .now)
        let daySpan = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
        let observedDays = max(daySpan, 1)
        let totalSpent = expenses.reduce(0) { $0 + $1.amount }
        return totalSpent / Double(observedDays)
    }

    var projectedMonthlySpend: Double {
        let daysInMonth = calendar.range(of: .day, in: .month, for: .now)?.count ?? 30
        return averageDailySpend * Double(daysInMonth)
    }

    var totalExpenseCount: Int {
        expenses.count
    }

    private func showFeedback(message: String, isError: Bool) {
        saveFeedback = Feedback(message: message, isError: isError)
        Task { [message] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                if saveFeedback?.message == message {
                    saveFeedback = nil
                }
            }
        }
    }
}
