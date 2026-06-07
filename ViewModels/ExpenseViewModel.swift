import SwiftUI

@MainActor
final class ExpenseViewModel: ObservableObject {
    struct Feedback: Equatable {
        let message: String
        let isError: Bool
    }

    struct CategoryBreakdown: Identifiable, Equatable {
        let category: ExpenseCategory
        let total: Double
        let count: Int

        var id: UUID { category.id }
    }

    @Published var expenses: [Expense]
    @Published var selectedCategory: ExpenseCategory
    @Published var amountText: String = ""
    @Published var merchantText: String = ""
    @Published var noteText: String = ""
    @Published var importText: String = ""
    @Published var saveFeedback: Feedback?
    @Published var parseFeedback: Feedback?

    let categories: [ExpenseCategory]

    private let store: ExpenseStore
    private let parser: ExpenseTextParser
    private let calendar: Calendar
    private let defaultCategory: ExpenseCategory

    init(
        store: ExpenseStore = ExpenseStore(),
        parser: ExpenseTextParser = ExpenseTextParser()
    ) {
        self.store = store
        self.parser = parser
        self.calendar = .current
        self.categories = ExpenseCategory.allDefaults
        let initialCategory = ExpenseCategory.allDefaults.last ?? .other
        self.defaultCategory = initialCategory
        self.expenses = store.loadExpenses()
        self.selectedCategory = initialCategory
    }

    func saveDraftExpense() {
        let sanitizedAmount = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAmount = sanitizedAmount.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(normalizedAmount), amount > 0 else {
            showSaveFeedback(message: "Enter a valid amount greater than zero.", isError: true)
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
        persistExpenses()
        resetDraftForm()
        showSaveFeedback(message: "Expense saved locally.", isError: false)
    }

    func parseImportedText() {
        let suggestion = parser.parse(importText, categories: categories)
        guard let suggestion else {
            showParseFeedback(message: "No usable amount or merchant found. You can still enter the expense manually.", isError: true)
            return
        }

        if let amount = suggestion.amount {
            amountText = String(format: "%.2f", amount)
        }

        if !suggestion.merchant.isEmpty {
            merchantText = suggestion.merchant
        }

        selectedCategory = suggestion.category
        showParseFeedback(message: suggestion.summary, isError: false)
    }

    func deleteExpense(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
        persistExpenses()
    }

    func deleteExpense(id: Expense.ID) {
        guard let index = expenses.firstIndex(where: { $0.id == id }) else { return }
        expenses.remove(at: index)
        persistExpenses()
    }

    func clearSaveFeedback() {
        saveFeedback = nil
    }

    func clearParseFeedback() {
        parseFeedback = nil
    }

    func expenses(matching category: ExpenseCategory?, timeFilter: HistoryTimeFilter) -> [Expense] {
        filteredExpenses(category: category, timeFilter: timeFilter)
            .sorted { $0.date > $1.date }
    }

    var todayTotal: Double {
        expenses(in: .today).reduce(0) { $0 + $1.amount }
    }

    var weekTotal: Double {
        expenses(in: .week).reduce(0) { $0 + $1.amount }
    }

    var monthTotal: Double {
        expenses(in: .month).reduce(0) { $0 + $1.amount }
    }

    var totalExpenseCount: Int {
        expenses.count
    }

    var expenseCountThisMonth: Int {
        expenses(in: .month).count
    }

    var averageExpenseAmount: Double {
        guard !expenses.isEmpty else { return 0 }
        return totalAmount / Double(expenses.count)
    }

    var averageDailySpend: Double {
        guard monthTotal > 0 else { return 0 }
        let elapsedDays = max(calendar.component(.day, from: .now), 1)
        return monthTotal / Double(elapsedDays)
    }

    var projectedMonthlySpend: Double {
        let daysInCurrentMonth = calendar.range(of: .day, in: .month, for: .now)?.count ?? 30
        return averageDailySpend * Double(daysInCurrentMonth)
    }

    var highestExpense: Expense? {
        expenses.max(by: { $0.amount < $1.amount })
    }

    var topCategory: ExpenseCategory? {
        categoryBreakdown.first?.category
    }

    var mostFrequentCategory: ExpenseCategory? {
        categoryBreakdown(by: .count).first?.category
    }

    var categoryBreakdown: [CategoryBreakdown] {
        categoryBreakdown(by: .amount)
    }

    var insightText: String {
        guard let topCategory else {
            return "Add your first micro-expense to see a spending pattern."
        }

        return "\(topCategory.displayName) is your top micro-expense category this month."
    }

    private var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private func filteredExpenses(category: ExpenseCategory?, timeFilter: HistoryTimeFilter) -> [Expense] {
        expenses.filter { expense in
            let categoryMatches = category == nil || expense.category.id == category?.id
            let timeMatches: Bool
            switch timeFilter {
            case .all:
                timeMatches = true
            case .today:
                timeMatches = calendar.isDateInToday(expense.date)
            case .week:
                timeMatches = isDate(expense.date, inside: .week)
            case .month:
                timeMatches = isDate(expense.date, inside: .month)
            }

            return categoryMatches && timeMatches
        }
    }

    private func expenses(in range: TimeRange) -> [Expense] {
        expenses.filter { expense in
            switch range {
            case .today:
                return calendar.isDateInToday(expense.date)
            case .week:
                return isDate(expense.date, inside: .week)
            case .month:
                return isDate(expense.date, inside: .month)
            }
        }
    }

    private func isDate(_ date: Date, inside range: TimeRange) -> Bool {
        switch range {
        case .today:
            return calendar.isDateInToday(date)
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return false }
            return interval.contains(date)
        case .month:
            guard let interval = calendar.dateInterval(of: .month, for: .now) else { return false }
            return interval.contains(date)
        }
    }

    private func categoryBreakdown(by sortMode: CategorySortMode) -> [CategoryBreakdown] {
        let sourceExpenses = expenses(in: .month)
        let grouped = Dictionary(grouping: sourceExpenses, by: { $0.category.id })

        let breakdown = grouped.compactMap { categoryID, items -> CategoryBreakdown? in
            guard let category = items.first?.category ?? sourceExpenses.first(where: { $0.category.id == categoryID })?.category else {
                return nil
            }
            return CategoryBreakdown(
                category: category,
                total: items.reduce(0) { $0 + $1.amount },
                count: items.count
            )
        }

        switch sortMode {
        case .amount:
            return breakdown.sorted { $0.total > $1.total }
        case .count:
            return breakdown.sorted {
                if $0.count == $1.count {
                    return $0.total > $1.total
                }
                return $0.count > $1.count
            }
        }
    }

    private func persistExpenses() {
        store.saveExpenses(expenses)
    }

    private func resetDraftForm() {
        amountText = ""
        merchantText = ""
        noteText = ""
        importText = ""
        selectedCategory = defaultCategory
        clearParseFeedback()
    }

    private func showSaveFeedback(message: String, isError: Bool) {
        saveFeedback = Feedback(message: message, isError: isError)
        clearFeedbackLater(kind: .save, message: message)
    }

    private func showParseFeedback(message: String, isError: Bool) {
        parseFeedback = Feedback(message: message, isError: isError)
        clearFeedbackLater(kind: .parse, message: message)
    }

    private func clearFeedbackLater(kind: FeedbackKind, message: String) {
        Task { [message] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                switch kind {
                case .save:
                    if saveFeedback?.message == message {
                        saveFeedback = nil
                    }
                case .parse:
                    if parseFeedback?.message == message {
                        parseFeedback = nil
                    }
                }
            }
        }
    }

    private enum FeedbackKind {
        case save
        case parse
    }

    private enum CategorySortMode {
        case amount
        case count
    }

    enum TimeRange {
        case today
        case week
        case month
    }
}

enum HistoryTimeFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .today:
            return "Today"
        case .week:
            return "Week"
        case .month:
            return "Month"
        }
    }
}
