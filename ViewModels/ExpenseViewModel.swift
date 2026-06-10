import SwiftUI

#if canImport(WidgetKit)
import WidgetKit
#endif

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

    struct CategoryShare: Identifiable, Equatable {
        let category: ExpenseCategory
        let total: Double
        let count: Int
        let percentage: Double

        var id: UUID { category.id }
    }

    struct CategorySpendPoint: Identifiable, Equatable {
        let category: ExpenseCategory
        let total: Double

        var id: UUID { category.id }
    }

    struct DailySpendPoint: Identifiable, Equatable {
        let date: Date
        let total: Double

        var id: Date { date }
    }

    struct WeeklySpendPoint: Identifiable, Equatable {
        let weekStart: Date
        let total: Double

        var id: Date { weekStart }
    }

    enum GoalStatus: Equatable {
        case none
        case onTrack
        case closeToLimit
        case limitReached
    }

    struct GoalOverview: Identifiable, Equatable {
        let cadence: SpendingGoalCadence
        let goal: SpendingGoal
        let spent: Double
        let remaining: Double
        let percentUsed: Double
        let progressFraction: Double
        let status: GoalStatus
        let daysLeftInPeriod: Int
        let remainingDailyBudget: Double
        let projectedMonthSpend: Double
        let statusText: String
        let motivationText: String

        var id: SpendingGoalCadence { cadence }

        var limitText: String {
            String(format: "$%.2f", goal.limit)
        }

        var spentText: String {
            String(format: "$%.2f", spent)
        }

        var remainingText: String {
            String(format: "$%.2f", remaining)
        }

        var percentUsedText: String {
            String(format: "%.0f%%", percentUsed)
        }
    }

    @Published var expenses: [Expense]
    @Published var selectedCategory: ExpenseCategory
    @Published var amountText: String = ""
    @Published var merchantText: String = ""
    @Published var noteText: String = ""
    @Published var importText: String = ""
    @Published var parsedExpense: ExpenseParseResult?
    @Published var saveFeedback: Feedback?
    @Published var parseFeedback: Feedback?
    @Published var weeklyGoal: SpendingGoal?
    @Published var monthlyGoal: SpendingGoal?
    @Published var isQuickAddInputFocused: Bool = false

    let categories: [ExpenseCategory]

    private let store: ExpenseStore
    private let goalStore: GoalStore
    private let parser: ExpenseTextParser
    private let widgetSummaryStore: WidgetSummaryStore
    private let calendar: Calendar
    private let defaultCategory: ExpenseCategory
    private var draftSource: ExpenseSource = .manual
    private var draftConfidence: Double = 1.0
    private var isResettingDraft = false

    init(
        store: ExpenseStore = ExpenseStore(),
        goalStore: GoalStore = GoalStore(),
        parser: ExpenseTextParser = ExpenseTextParser()
    ) {
        self.store = store
        self.goalStore = goalStore
        self.parser = parser
        self.widgetSummaryStore = WidgetSummaryStore()
        self.calendar = .current
        self.categories = ExpenseCategory.allDefaults
        let initialCategory = ExpenseCategory.allDefaults.last ?? .other
        self.defaultCategory = initialCategory
        self.expenses = store.loadExpenses()
        let goals = goalStore.loadGoals()
        self.weeklyGoal = goals.weekly
        self.monthlyGoal = goals.monthly
        self.selectedCategory = initialCategory
        syncWidgetSummary()
    }

    func saveDraftExpense() {
        let previousWeeklyStatus = goalStatus(for: .weekly)
        let previousMonthlyStatus = goalStatus(for: .monthly)
        let strings = AppStrings.current()
        let sanitizedAmount = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAmount = sanitizedAmount.replacingOccurrences(of: ",", with: ".")
        let parsedAmount = parsedExpense?.amount
        guard let amount = Double(normalizedAmount) ?? parsedAmount, amount > 0 else {
            showSaveFeedback(message: strings.saveMissingAmountError, isError: true)
            HapticsService.shared.error()
            return
        }

        let expense = Expense(
            amount: amount,
            category: selectedCategory,
            merchant: merchantText.trimmingCharacters(in: .whitespacesAndNewlines),
            note: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
            source: draftSource,
            confidence: draftSource == .parsedText ? draftConfidence : 1.0
        )

        expenses.insert(expense, at: 0)
        persistExpenses()
        resetDraftForm()
        triggerPostSaveHaptic(previousWeeklyStatus: previousWeeklyStatus, previousMonthlyStatus: previousMonthlyStatus)
        showSaveFeedback(message: "Expense saved", isError: false)
    }

    func parseImportedText() {
        let strings = AppStrings.current()
        let suggestion = parser.parse(importText, categories: categories)
        guard let suggestion else {
            parsedExpense = nil
            showParseFeedback(message: strings.parseNoResultMessage, isError: true)
            HapticsService.shared.error()
            return
        }

        guard suggestion.amount != nil else {
            parsedExpense = nil
            showParseFeedback(message: strings.missingAmountParseError, isError: true)
            HapticsService.shared.error()
            return
        }

        parsedExpense = suggestion
        applyParsedSuggestion(suggestion)
        draftConfidence = suggestion.confidence
        showParseFeedback(message: suggestion.summary, isError: false)
    }

    func useParsedExpense() {
        guard let parsedExpense else { return }
        applyParsedSuggestion(parsedExpense)
        self.parsedExpense = nil
        clearParseFeedback()
    }

    func prefillDraft(amount: String? = nil, merchant: String? = nil, category: String? = nil, source: ExpenseSource = .imported) {
        parsedExpense = nil
        if let amount, !amount.isEmpty {
            amountText = amount
        }

        if let merchant, !merchant.isEmpty {
            merchantText = merchant
        }

        if let category, let matchedCategory = ExpenseCategory.category(matching: category, in: categories) {
            selectedCategory = matchedCategory
        }

        draftSource = source
        draftConfidence = 1.0
    }

    func resetDraftForExternalEntry() {
        isResettingDraft = true
        amountText = ""
        merchantText = ""
        noteText = ""
        importText = ""
        parsedExpense = nil
        saveFeedback = nil
        parseFeedback = nil
        selectedCategory = defaultCategory
        draftSource = .manual
        draftConfidence = 1.0
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            isResettingDraft = false
        }
    }

    func loadImportedTextAndParse(_ text: String) {
        resetDraftForExternalEntry()
        importText = text
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000)
            self.parseImportedText()
        }
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

    func clearAllExpenses() {
        expenses.removeAll()
        persistExpenses()
        parsedExpense = nil
        saveFeedback = nil
        parseFeedback = nil
    }

    func clearAllData() {
        clearAllExpenses()
        clearAllGoals()
    }

    func clearAllGoals() {
        weeklyGoal = nil
        monthlyGoal = nil
        persistGoals()
    }

    func saveGoal(cadence: SpendingGoalCadence, limit: Double) {
        guard limit > 0 else { return }
        switch cadence {
        case .weekly:
            weeklyGoal = SpendingGoal(cadence: .weekly, limit: limit, createdAt: weeklyGoal?.createdAt ?? .now, updatedAt: .now)
        case .monthly:
            monthlyGoal = SpendingGoal(cadence: .monthly, limit: limit, createdAt: monthlyGoal?.createdAt ?? .now, updatedAt: .now)
        }
        persistGoals()
    }

    func removeGoal(cadence: SpendingGoalCadence) {
        switch cadence {
        case .weekly:
            weeklyGoal = nil
        case .monthly:
            monthlyGoal = nil
        }
        persistGoals()
    }

    func clearSaveFeedback() {
        guard !isResettingDraft else { return }
        saveFeedback = nil
    }

    func clearParseFeedback() {
        parseFeedback = nil
    }

    func setParseFeedback(message: String, isError: Bool) {
        parseFeedback = Feedback(message: message, isError: isError)
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
        projectedMonthSpend
    }

    var projectedMonthSpend: Double {
        let daysInCurrentMonth = calendar.range(of: .day, in: .month, for: .now)?.count ?? 30
        return averageDailySpend * Double(daysInCurrentMonth)
    }

    var daysLeftInMonth: Int {
        daysLeft(in: .month)
    }

    var daysLeftInWeek: Int {
        daysLeft(in: .week)
    }

    var highestExpense: Expense? {
        expenses.max(by: { $0.amount < $1.amount })
    }

    var largestExpenseThisMonth: Expense? {
        expenses(in: .month).max(by: { $0.amount < $1.amount })
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

    var categorySpendChartData: [CategorySpendPoint] {
        categoryBreakdown.map {
            CategorySpendPoint(category: $0.category, total: $0.total)
        }
    }

    var topCategorySharesThisMonth: [CategoryShare] {
        Array(categorySharesThisMonth.prefix(3))
    }

    var categorySharesThisMonth: [CategoryShare] {
        let monthBreakdown = categoryBreakdown
        let monthTotal = self.monthTotal
        guard monthTotal > 0 else { return [] }

        return monthBreakdown.map { item in
            CategoryShare(
                category: item.category,
                total: item.total,
                count: item.count,
                percentage: (item.total / monthTotal) * 100
            )
        }
    }

    var recentSpendTrendData: [DailySpendPoint] {
        let daysToShow = 14
        guard let startDate = calendar.date(byAdding: .day, value: -(daysToShow - 1), to: calendar.startOfDay(for: .now)) else {
            return []
        }

        let totalsByDay = Dictionary(
            grouping: expenses,
            by: { calendar.startOfDay(for: $0.date) }
        ).mapValues { items in
            items.reduce(0) { $0 + $1.amount }
        }

        return (0..<daysToShow).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else {
                return nil
            }

            return DailySpendPoint(
                date: date,
                total: totalsByDay[date] ?? 0
            )
        }
    }

    var weeklySpendTrendData: [WeeklySpendPoint] {
        let weeksToShow = 6
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start else {
            return []
        }

        let totalsByWeek = Dictionary(
            grouping: expenses,
            by: { expense in
                calendar.dateInterval(of: .weekOfYear, for: expense.date)?.start ?? calendar.startOfDay(for: expense.date)
            }
        ).mapValues { items in
            items.reduce(0) { $0 + $1.amount }
        }

        return (0..<weeksToShow).compactMap { offset in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: offset - (weeksToShow - 1), to: currentWeekStart) else {
                return nil
            }

            return WeeklySpendPoint(
                weekStart: weekStart,
                total: totalsByWeek[weekStart] ?? 0
            )
        }
    }

    var hasWeeklyTrendData: Bool {
        Set(
            expenses.compactMap { expense in
                calendar.dateInterval(of: .weekOfYear, for: expense.date)?.start
            }
        ).count >= 2
    }

    var insightText: String {
        guard let topCategory else {
            return "Add your first micro-expense to see a spending pattern."
        }

        return "\(topCategory.displayName) is your top micro-expense category this month."
    }

    var monthCategorySummaryText: String {
        guard let topShare = topCategorySharesThisMonth.first else {
            return "Add a few expenses to see where most leaks land."
        }

        return "\(topShare.category.displayName) is \(percentageString(topShare.percentage)) of your tracked leaks this month."
    }

    var categoryDistributionAccessibilitySummary: String {
        let shares = categorySharesThisMonth
        guard !shares.isEmpty else {
            return AppStrings.current().dashboardNoCategoryDistribution
        }

        return shares
            .map { "\($0.category.displayName) \(percentageString($0.percentage))" }
            .joined(separator: ", ")
    }

    var recentTrendAccessibilitySummary: String {
        let points = recentSpendTrendData
        guard !points.isEmpty else {
            return AppStrings.current().dashboardNoRecentTrend
        }

        let total = points.reduce(0) { $0 + $1.total }
        guard let peak = points.max(by: { $0.total < $1.total }) else {
            return "14-day trend. Total \(currency(total))."
        }

        let peakDate = peak.date.formatted(date: .abbreviated, time: .omitted)
        return "14-day trend. Total \(currency(total)). Peak \(currency(peak.total)) on \(peakDate)."
    }

    var weeklyTrendAccessibilitySummary: String {
        let points = weeklySpendTrendData
        guard !points.isEmpty else {
            return AppStrings.current().insightsWeeklyTotalsTitle
        }

        let total = points.reduce(0) { $0 + $1.total }
        guard let peak = points.max(by: { $0.total < $1.total }) else {
            return "6-week trend. Total \(currency(total))."
        }

        let peakDate = peak.weekStart.formatted(date: .abbreviated, time: .omitted)
        return "6-week trend. Total \(currency(total)). Peak \(currency(peak.total)) on \(peakDate)."
    }

    var largestExpenseThisMonthText: String {
        guard let largestExpenseThisMonth else { return "—" }
        return currency(largestExpenseThisMonth.amount)
    }

    var largestExpenseThisMonthSubtitle: String {
        guard let largestExpenseThisMonth else {
            return "No expenses this month yet"
        }

        return largestExpenseThisMonth.merchant.isEmpty ? largestExpenseThisMonth.category.displayName : largestExpenseThisMonth.merchant
    }

    var monthlySummaryReportText: String {
        let topCategoryText: String
        if let top = topCategorySharesThisMonth.first {
            topCategoryText = "\(top.category.displayName) (\(percentageString(top.percentage)))"
        } else {
            topCategoryText = "None yet"
        }

        let largestExpenseText = largestExpenseThisMonth.map { expense in
            let merchant = expense.merchant.isEmpty ? expense.category.displayName : expense.merchant
            return "\(currency(expense.amount)) at \(merchant)"
        } ?? "None yet"

        return [
            "Pocket Leak - Monthly Summary",
            "Total this month: \(currency(monthTotal))",
            "Expenses this month: \(expenseCountThisMonth)",
            "Average expense: \(currency(averageExpenseAmount))",
            "Top category: \(topCategoryText)",
            "Largest expense: \(largestExpenseText)"
        ].joined(separator: "\n")
    }

    func goal(for cadence: SpendingGoalCadence) -> SpendingGoal? {
        switch cadence {
        case .weekly:
            return weeklyGoal
        case .monthly:
            return monthlyGoal
        }
    }

    func goalSpentAmount(for cadence: SpendingGoalCadence) -> Double {
        switch cadence {
        case .weekly:
            return weekTotal
        case .monthly:
            return monthTotal
        }
    }

    func goalRemainingAmount(for cadence: SpendingGoalCadence) -> Double {
        guard let goal = goal(for: cadence) else { return 0 }
        return max(goal.limit - goalSpentAmount(for: cadence), 0)
    }

    func goalPercentUsed(for cadence: SpendingGoalCadence) -> Double {
        guard let goal = goal(for: cadence), goal.limit > 0 else { return 0 }
        return min((goalSpentAmount(for: cadence) / goal.limit) * 100, 999)
    }

    func goalStatusText(for cadence: SpendingGoalCadence) -> String {
        let strings = AppStrings.current()
        guard goal(for: cadence) != nil else { return strings.goalsNoGoalStatus }

        switch goalStatus(for: cadence) {
        case .limitReached:
            return strings.goalsStatusLimitReached
        case .closeToLimit:
            return strings.goalsStatusCloseToLimit
        case .onTrack:
            return strings.goalsStatusOnTrack
        case .none:
            return strings.goalsNoGoalStatus
        }
    }

    func goalProgressFraction(for cadence: SpendingGoalCadence) -> Double {
        guard let goal = goal(for: cadence), goal.limit > 0 else { return 0 }
        return min(goalSpentAmount(for: cadence) / goal.limit, 1)
    }

    func goalStatus(for cadence: SpendingGoalCadence) -> GoalStatus {
        guard goal(for: cadence) != nil else { return .none }

        switch goalPercentUsed(for: cadence) {
        case 100...:
            return .limitReached
        case 75..<100:
            return .closeToLimit
        default:
            return .onTrack
        }
    }

    func goalMotivationText(for cadence: SpendingGoalCadence) -> String {
        let strings = AppStrings.current()
        guard let goal = goal(for: cadence) else {
            return strings.goalsNoGoalMessage
        }

        switch (goal.cadence, goalStatus(for: cadence)) {
        case (_, .limitReached):
            return goal.cadence == .weekly ? strings.goalsWeeklyLimitReachedMessage : strings.goalsMonthlyLimitReachedMessage
        case (_, .closeToLimit):
            return goal.cadence == .weekly ? strings.goalsWeeklyCloseToLimitMessage : strings.goalsMonthlyCloseToLimitMessage
        case (_, .onTrack):
            if goal.cadence == .weekly {
                return String(format: strings.goalsWeeklyOnTrackMessageTemplate, currency(remainingDailyBudget(for: cadence)))
            } else {
                return String(
                    format: strings.goalsMonthlyOnTrackMessageTemplate,
                    currency(remainingDailyBudget(for: cadence)),
                    currency(projectedMonthSpend)
                )
            }
        case (_, .none):
            return strings.goalsNoGoalMessage
        }
    }

    func goalPeriodLabel(for cadence: SpendingGoalCadence) -> String {
        switch cadence {
        case .weekly:
            return AppStrings.current().goalsPeriodThisWeek
        case .monthly:
            return AppStrings.current().goalsPeriodThisMonth
        }
    }

    func goalLimitText(for cadence: SpendingGoalCadence) -> String {
        guard let goal = goal(for: cadence) else { return "—" }
        return currency(goal.limit)
    }

    func goalSpentText(for cadence: SpendingGoalCadence) -> String {
        currency(goalSpentAmount(for: cadence))
    }

    func goalRemainingText(for cadence: SpendingGoalCadence) -> String {
        currency(goalRemainingAmount(for: cadence))
    }

    func goalPercentUsedText(for cadence: SpendingGoalCadence) -> String {
        String(format: "%.0f%%", goalPercentUsed(for: cadence))
    }

    func goalDaysLeftText(for cadence: SpendingGoalCadence) -> String {
        let daysLeft = cadence == .weekly ? daysLeftInWeek : daysLeftInMonth
        return "\(daysLeft)"
    }

    func goalRemainingDailyBudgetText(for cadence: SpendingGoalCadence) -> String {
        currency(remainingDailyBudget(for: cadence))
    }

    func goalProjectedMonthSpendText() -> String {
        currency(projectedMonthSpend)
    }

    func goalOverview(for cadence: SpendingGoalCadence) -> GoalOverview? {
        guard let goal = goal(for: cadence) else { return nil }

        let spent = goalSpentAmount(for: cadence)
        let remaining = goalRemainingAmount(for: cadence)
        let percentUsed = goalPercentUsed(for: cadence)
        let status = goalStatus(for: cadence)

        return GoalOverview(
            cadence: cadence,
            goal: goal,
            spent: spent,
            remaining: remaining,
            percentUsed: percentUsed,
            progressFraction: goalProgressFraction(for: cadence),
            status: status,
            daysLeftInPeriod: cadence == .weekly ? daysLeftInWeek : daysLeftInMonth,
            remainingDailyBudget: remainingDailyBudget(for: cadence),
            projectedMonthSpend: projectedMonthSpend,
            statusText: goalStatusText(for: cadence),
            motivationText: goalMotivationText(for: cadence)
        )
    }

    func goalAccessibilityValue(for cadence: SpendingGoalCadence) -> String {
        guard let overview = goalOverview(for: cadence) else {
            return AppStrings.current().goalsNoGoalMessage
        }

        return [
            overview.limitText,
            overview.spentText,
            overview.remainingText,
            overview.percentUsedText,
            overview.statusText,
            overview.motivationText
        ]
        .joined(separator: ". ")
    }

    func expenseAccessibilitySummary(for expense: Expense) -> String {
        let merchant = expense.merchant.isEmpty ? expense.category.displayName : expense.merchant
        let note = expense.note.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteText = note.isEmpty ? "" : ". Note: \(note)"
        return "\(currency(expense.amount)) in \(expense.category.displayName). Merchant: \(merchant). \(expense.date.formatted(date: .abbreviated, time: .shortened))\(noteText)"
    }

    var goalOverviews: [GoalOverview] {
        [goalOverview(for: .weekly), goalOverview(for: .monthly)].compactMap { $0 }
    }

    func remainingDailyBudget(for cadence: SpendingGoalCadence) -> Double {
        let remaining = goalRemainingAmount(for: cadence)
        let daysLeft = max(cadence == .weekly ? daysLeftInWeek : daysLeftInMonth, 1)
        return remaining / Double(daysLeft)
    }

    func remainingWeeklyBudget(for cadence: SpendingGoalCadence) -> Double {
        switch cadence {
        case .weekly:
            return goalRemainingAmount(for: cadence)
        case .monthly:
            let weeksLeft = max(daysLeftInMonth / 7, 1)
            return goalRemainingAmount(for: cadence) / Double(weeksLeft)
        }
    }

    var hasWeeklyGoal: Bool {
        weeklyGoal != nil
    }

    var hasMonthlyGoal: Bool {
        monthlyGoal != nil
    }

    var hasGoal: Bool {
        hasWeeklyGoal || hasMonthlyGoal
    }

    var csvExport: ExpenseCSVExport {
        ExpenseCSVExport(expenses: expenses)
    }

    var jsonExport: ExpenseJSONExport {
        ExpenseJSONExport(expenses: expenses)
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
        expenses = store.loadExpenses()
        syncWidgetSummary()
    }

    private func persistGoals() {
        goalStore.saveGoals(SpendingGoals(weekly: weeklyGoal, monthly: monthlyGoal))
        let savedGoals = goalStore.loadGoals()
        weeklyGoal = savedGoals.weekly
        monthlyGoal = savedGoals.monthly
        syncWidgetSummary()
    }

    private func resetDraftForm() {
        isResettingDraft = true
        amountText = ""
        merchantText = ""
        noteText = ""
        importText = ""
        parsedExpense = nil
        selectedCategory = defaultCategory
        draftSource = .manual
        draftConfidence = 1.0
        clearParseFeedback()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            isResettingDraft = false
        }
    }

    private func showSaveFeedback(message: String, isError: Bool) {
        if saveFeedback?.message == message, saveFeedback?.isError == isError {
            return
        }
        saveFeedback = Feedback(message: message, isError: isError)
        clearFeedbackLater(kind: .save, message: message)
    }

    private func showParseFeedback(message: String, isError: Bool) {
        if parseFeedback?.message == message, parseFeedback?.isError == isError {
            return
        }
        parseFeedback = Feedback(message: message, isError: isError)
        clearFeedbackLater(kind: .parse, message: message)
    }

    private func clearFeedbackLater(kind: FeedbackKind, message: String) {
        Task { [message] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
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

    private func currency(_ amount: Double) -> String {
        String(format: "$%.2f", amount)
    }

    private func percentageString(_ value: Double) -> String {
        String(format: "%.0f%%", value)
    }

    private func applyParsedSuggestion(_ suggestion: ExpenseParseResult) {
        if let amount = suggestion.amount {
            amountText = String(format: "%.2f", amount)
        }

        if !suggestion.merchant.isEmpty {
            merchantText = suggestion.merchant
        }

        selectedCategory = suggestion.category
        draftSource = suggestion.source
        draftConfidence = suggestion.confidence
    }

    private func daysLeft(in range: TimeRange) -> Int {
        switch range {
        case .today:
            return 1
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return 7 }
            let start = calendar.startOfDay(for: .now)
            let end = calendar.startOfDay(for: interval.end)
            let difference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
            return max(difference, 1)
        case .month:
            guard let interval = calendar.dateInterval(of: .month, for: .now) else { return 30 }
            let start = calendar.startOfDay(for: .now)
            let end = calendar.startOfDay(for: interval.end)
            let difference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
            return max(difference, 1)
        }
    }

    private func syncWidgetSummary() {
        let hasContent = !expenses.isEmpty || hasGoal
        guard hasContent else {
            widgetSummaryStore.clearSummary()
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
            return
        }

        let summary = WidgetSummary(
            date: .now,
            todayTotal: todayTotal,
            weekTotal: weekTotal,
            monthTotal: monthTotal,
            topCategory: topCategory?.displayName ?? "No spending yet",
            weeklyGoalStatus: widgetGoalStatus(for: .weekly),
            monthlyGoalStatus: widgetGoalStatus(for: .monthly),
            categoryTop3: categoryBreakdown.prefix(3).map { WidgetCategorySummary(name: $0.category.displayName, amount: $0.total) }
        )

        widgetSummaryStore.saveSummary(summary)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private func widgetGoalStatus(for cadence: SpendingGoalCadence) -> WidgetGoalStatus {
        switch goalStatus(for: cadence) {
        case .none:
            return .none
        case .onTrack:
            return .onTrack
        case .closeToLimit:
            return .closeToLimit
        case .limitReached:
            return .limitReached
        }
    }

    private func triggerPostSaveHaptic(previousWeeklyStatus: GoalStatus, previousMonthlyStatus: GoalStatus) {
        let newWeeklyStatus = goalStatus(for: .weekly)
        let newMonthlyStatus = goalStatus(for: .monthly)

        if didCrossGoalThreshold(from: previousWeeklyStatus, to: newWeeklyStatus) ||
            didCrossGoalThreshold(from: previousMonthlyStatus, to: newMonthlyStatus) {
            HapticsService.shared.warning()
        } else {
            HapticsService.shared.success()
        }
    }

    private func didCrossGoalThreshold(from previous: GoalStatus, to new: GoalStatus) -> Bool {
        switch (previous, new) {
        case (.onTrack, .closeToLimit), (.onTrack, .limitReached), (.none, .closeToLimit), (.none, .limitReached):
            return true
        default:
            return false
        }
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
