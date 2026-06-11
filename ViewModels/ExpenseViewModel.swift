import Foundation
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

    struct DashboardCategorySummary: Identifiable, Equatable {
        let key: String
        let categoryName: String
        let total: Double
        let count: Int
        let percentage: Double
        let accentColor: Color

        var id: String { key }
    }

    struct DashboardTrendPoint: Identifiable, Equatable {
        let index: Int
        let date: Date
        let total: Double

        var id: Int { index }
    }

    struct DashboardTopCategorySignal: Identifiable, Equatable {
        let key: String
        let categoryName: String
        let total: Double
        let percentage: Double
        let count: Int
        let accentColor: Color

        var id: String { key }
    }

    struct DashboardSignal: Identifiable, Equatable {
        enum Kind: Equatable {
            case budget
            case topCategory
        }

        let id: String
        let kind: Kind
        let title: String
        let detail: String
        let accentColor: Color
    }

    struct DashboardCategoryBudgetSignal: Identifiable, Equatable {
        let id: String
        let categoryName: String
        let cadenceText: String
        let spentText: String
        let limitText: String
        let remainingText: String
        let percentText: String
        let progressFraction: Double
        let statusText: String
        let accentColor: Color
    }

    struct DashboardRecurringSignal: Identifiable, Equatable {
        let id: UUID
        let merchant: String
        let amountText: String
        let categoryName: String
        let dueDateText: String
        let cadenceText: String
        let accentColor: Color
    }

    struct DashboardSmartInsight: Identifiable, Equatable {
        let id: String
        let title: String
        let message: String
        let symbolName: String
        let accentColor: Color
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

    struct CategoryBudgetOverview: Identifiable, Equatable {
        let budget: CategoryBudget
        let spent: Double
        let remaining: Double
        let percentUsed: Double
        let progressFraction: Double
        let status: CategoryBudgetStatus

        var id: UUID { budget.id }

        var limitText: String {
            String(format: "$%.2f", budget.limit)
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
    @Published var categoryBudgets: [CategoryBudget] = []
    @Published var recurringExpenses: [RecurringExpense] = []
    @Published var goalForecasts: [GoalForecast] = []
    @Published var spendingComparisons: [SpendingComparison] = []
    @Published var smartInsights: [SmartInsight] = []
    @Published var smartAlerts: [SmartAlert] = []
    @Published var weeklyDigest: WeeklyDigest
    @Published var isQuickAddInputFocused: Bool = false
    @Published var isGoalsInputFocused: Bool = false
    @Published var privacyModeHideAmounts: Bool = UserDefaults.standard.bool(forKey: AppPreferenceKeys.privacyModeHideAmounts)
    @Published var hideAmountsInWidgets: Bool = UserDefaults.standard.bool(forKey: AppPreferenceKeys.hideAmountsInWidgets)

    let categories: [ExpenseCategory]

    private let store: ExpenseStore
    private let goalStore: GoalStore
    private let categoryBudgetStore: CategoryBudgetStore
    private let recurringExpenseStore: RecurringExpenseStore
    private let parser: ExpenseTextParser
    private let goalIntelligenceService: GoalIntelligenceService
    private let spendingComparisonService: SpendingComparisonService
    private let smartInsightsService: SmartInsightsService
    private let smartAlertService: SmartAlertService
    private let weeklyDigestService: WeeklyDigestService
    private let widgetSummaryStore: WidgetSummaryStore
    private let localNotificationService: LocalNotificationService
    private let calendar: Calendar
    private let defaultCategory: ExpenseCategory
    private var draftSource: ExpenseSource = .manual
    private var draftConfidence: Double = 1.0
    private var isResettingDraft = false
    private var smartAlertsDefaultsObserver: NSObjectProtocol?

    init(
        store: ExpenseStore = ExpenseStore(),
        goalStore: GoalStore = GoalStore(),
        categoryBudgetStore: CategoryBudgetStore = CategoryBudgetStore(),
        recurringExpenseStore: RecurringExpenseStore = RecurringExpenseStore(),
        parser: ExpenseTextParser = ExpenseTextParser()
    ) {
        self.store = store
        self.goalStore = goalStore
        self.categoryBudgetStore = categoryBudgetStore
        self.recurringExpenseStore = recurringExpenseStore
        self.parser = parser
        self.goalIntelligenceService = GoalIntelligenceService()
        self.spendingComparisonService = SpendingComparisonService()
        self.smartInsightsService = SmartInsightsService()
        self.smartAlertService = SmartAlertService()
        self.weeklyDigestService = WeeklyDigestService()
        self.widgetSummaryStore = WidgetSummaryStore()
        self.localNotificationService = LocalNotificationService.shared
        self.calendar = .current
        self.categories = ExpenseCategory.allDefaults
        let initialCategory = ExpenseCategory.allDefaults.last ?? .other
        self.defaultCategory = initialCategory
        self.expenses = store.loadExpenses()
        let goals = goalStore.loadGoals()
        self.weeklyGoal = goals.weekly
        self.monthlyGoal = goals.monthly
        self.categoryBudgets = categoryBudgetStore.loadBudgets()
        self.recurringExpenses = recurringExpenseStore.loadRecurringExpenses()
        self.selectedCategory = initialCategory
        self.privacyModeHideAmounts = UserDefaults.standard.bool(forKey: AppPreferenceKeys.privacyModeHideAmounts)
        self.hideAmountsInWidgets = UserDefaults.standard.bool(forKey: AppPreferenceKeys.hideAmountsInWidgets)
        self.weeklyDigest = WeeklyDigest(
            weekStart: .now,
            weekEnd: .now,
            totalSpend: 0,
            expenseCount: 0,
            topCategory: nil,
            averageDailySpend: 0,
            largestExpense: nil,
            bestInsight: nil,
            goalStatus: nil,
            comparisonVsLastWeek: nil
        )
        print("Loaded goals:", String(describing: self.weeklyGoal), String(describing: self.monthlyGoal))

        smartAlertsDefaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshSmartAlerts()
            }
        }
    }

    deinit {
        if let smartAlertsDefaultsObserver {
            NotificationCenter.default.removeObserver(smartAlertsDefaultsObserver)
        }
    }

    func saveDraftExpense() {
        let previousWeeklyStatus = goalStatus(for: .weekly)
        let previousMonthlyStatus = goalStatus(for: .monthly)
        let strings = AppStrings.current()
        let amount = parsedAmount(from: amountText)

        guard let amount, amount.isFinite, amount > 0 else {
            showSaveFeedback(message: strings.saveMissingAmountError, isError: true)
            HapticsService.shared.error()
            return
        }

        let savedSource: ExpenseSource = draftSource
        let savedConfidence: Double = safeConfidence(draftConfidence)

        let expense = Expense(
            amount: amount,
            category: selectedCategory,
            merchant: merchantText.trimmingCharacters(in: .whitespacesAndNewlines),
            note: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
            source: savedSource,
            confidence: savedConfidence
        )

        expenses.insert(expense, at: 0)
        persistExpenses()
        resetDraftForm()
        triggerPostSaveHaptic(previousWeeklyStatus: previousWeeklyStatus, previousMonthlyStatus: previousMonthlyStatus)
        showSaveFeedback(message: "Expense saved", isError: false)
    }

    func parseImportedText() {
        let strings = AppStrings.current()
        let text = importText.trimmingCharacters(in: .whitespacesAndNewlines)
        print("Parse Text started")
        print("Parse Text input:", importText)
        guard !text.isEmpty else {
            parsedExpense = nil
            print("Parse Text failed safely")
            showParseFeedback(message: strings.parseNoResultMessage, isError: true)
            HapticsService.shared.error()
            return
        }

        let suggestion = parser.parse(text, categories: categories)
        print("Parse Text result:", String(describing: suggestion))
        guard let suggestion else {
            parsedExpense = nil
            print("Parse Text failed safely")
            showParseFeedback(message: strings.parseNoResultMessage, isError: true)
            HapticsService.shared.error()
            return
        }

        guard let amount = suggestion.amount, amount.isFinite, amount > 0 else {
            parsedExpense = nil
            print("Parse Text failed safely")
            showParseFeedback(message: strings.missingAmountParseError, isError: true)
            HapticsService.shared.error()
            return
        }

        guard suggestion.confidence.isFinite else {
            parsedExpense = nil
            print("Parse Text failed safely")
            showParseFeedback(message: strings.parseNoResultMessage, isError: true)
            HapticsService.shared.error()
            return
        }

        let resolvedAmountText = amountText(for: amount)
        let resolvedMerchantText = suggestion.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedCategory = resolvedCategory(from: suggestion.category)

        amountText = resolvedAmountText
        merchantText = resolvedMerchantText
        selectedCategory = resolvedCategory
        draftSource = .parsedText
        draftConfidence = safeConfidence(suggestion.confidence)
        parsedExpense = nil
        let merchant = merchantText.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedMessage = merchant.isEmpty
            ? "Parsed \(resolvedAmountText) • \(selectedCategory.displayName)"
            : "Parsed \(resolvedAmountText) • \(merchant) • \(selectedCategory.displayName)"
        showParseFeedback(message: parsedMessage, isError: false)
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
        loadImportedText(text, autoParse: true)
    }

    func loadImportedText(_ text: String) {
        loadImportedText(text, autoParse: false)
    }

    private func loadImportedText(_ text: String, autoParse: Bool) {
        let sanitized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        resetDraftForExternalEntry()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000)
            self.importText = sanitized
            self.parsedExpense = nil
            self.parseFeedback = nil
            self.draftSource = .imported
            self.draftConfidence = 1.0
            if autoParse {
                self.parseImportedText()
            }
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
        clearAllCategoryBudgets()
        clearAllRecurringExpenses()
        smartAlertService.clearDismissedAlerts()
        refreshSmartAlerts()
        syncLocalNotifications()
    }

    func restoreBackup(
        _ backup: DataBackupDocument,
        mode: DataBackupRestoreMode
    ) -> DataBackupRestorationSummary {
        let importedExpenses = backup.expenses
            .filter { $0.amount.isFinite && $0.amount > 0 }
            .sorted { $0.date > $1.date }
        let importedGoals = backup.goals.sanitized
        let importedBudgets = backup.categoryBudgets.filter { $0.isValid }
        let importedRecurringExpenses = backup.recurringExpenses.filter { $0.isValid }

        switch mode {
        case .replace:
            expenses = importedExpenses
            weeklyGoal = importedGoals.weekly
            monthlyGoal = importedGoals.monthly
            categoryBudgets = importedBudgets
            recurringExpenses = importedRecurringExpenses
        case .merge:
            expenses = mergeExpenses(current: expenses, imported: importedExpenses)
            weeklyGoal = weeklyGoal ?? importedGoals.weekly
            monthlyGoal = monthlyGoal ?? importedGoals.monthly
            categoryBudgets = mergeCategoryBudgets(current: categoryBudgets, imported: importedBudgets)
            recurringExpenses = mergeRecurringExpenses(current: recurringExpenses, imported: importedRecurringExpenses)
        }

        persistExpenses(refreshDerivedState: false)
        persistGoals(refreshDerivedState: false)
        persistCategoryBudgets()
        persistRecurringExpenses()
        refreshGoalForecasts()
        refreshSpendingComparisons()
        refreshSmartInsights()
        refreshSmartAlerts()
        refreshWeeklyDigest()
        syncWidgetSummary()
        syncLocalNotifications()

        return DataBackupRestorationSummary(
            expenseCount: importedExpenses.count,
            goalCount: importedGoals.activeGoals.count,
            categoryBudgetCount: importedBudgets.count,
            recurringExpenseCount: importedRecurringExpenses.count,
            settingsApplied: backup.settings != nil
        )
    }

#if DEBUG
    func loadDemoData() {
        print("Generating demo data")
        clearAllData()

        expenses = store.sampleExpenses().sorted { $0.date > $1.date }
        persistExpenses()

        saveGoal(cadence: .weekly, limit: 180)
        saveGoal(cadence: .monthly, limit: 760)

        saveCategoryBudget(category: .coffee, cadence: .monthly, limit: 80)
        saveCategoryBudget(category: .transport, cadence: .monthly, limit: 120)
        saveRecurringExpense(
            merchant: "Netflix",
            amount: 149.0,
            category: .entertainment,
            cadence: .monthly,
            nextDueDate: calendar.date(byAdding: .day, value: 7, to: .now) ?? .now
        )

        refreshGoalForecasts()
        refreshSpendingComparisons()
        refreshSmartInsights()
        refreshSmartAlerts()
        refreshWeeklyDigest()
        syncWidgetSummary()
        syncLocalNotifications()

        showSaveFeedback(message: "Demo data generated", isError: false)
    }
#endif

    func clearAllGoals() {
        weeklyGoal = nil
        monthlyGoal = nil
        persistGoals(refreshDerivedState: false)
    }

    func clearAllCategoryBudgets() {
        categoryBudgets.removeAll()
        persistCategoryBudgets()
    }

    func clearAllRecurringExpenses() {
        recurringExpenses.removeAll()
        persistRecurringExpenses()
    }

    func dismissSmartAlert(id: String) {
        smartAlertService.dismissAlert(id: id)
        refreshSmartAlerts()
    }

    func saveGoal(cadence: SpendingGoalCadence, limit: Double) {
        guard limit.isFinite, limit > 0 else { return }
        print("Saving \(cadence.rawValue) goal:", limit)
        switch cadence {
        case .weekly:
            weeklyGoal = SpendingGoal(cadence: .weekly, limit: limit, createdAt: weeklyGoal?.createdAt ?? .now, updatedAt: .now)
        case .monthly:
            monthlyGoal = SpendingGoal(cadence: .monthly, limit: limit, createdAt: monthlyGoal?.createdAt ?? .now, updatedAt: .now)
        }
        persistGoals(refreshDerivedState: false)
    }

    func removeGoal(cadence: SpendingGoalCadence) {
        print("Removing \(cadence.rawValue) goal")
        switch cadence {
        case .weekly:
            weeklyGoal = nil
        case .monthly:
            monthlyGoal = nil
        }
        persistGoals(refreshDerivedState: false)
    }

    func saveCategoryBudget(
        budgetID: UUID? = nil,
        category: ExpenseCategory,
        cadence: SpendingGoalCadence,
        limit: Double,
        isActive: Bool = true
    ) {
        guard limit.isFinite, limit > 0 else {
            print("Invalid budget ignored:", limit)
            return
        }

        let resolvedCategory = resolvedCategory(from: category)
        let sanitizedBudget = CategoryBudget(
            id: budgetID ?? UUID(),
            category: resolvedCategory,
            cadence: cadence,
            limit: limit,
            createdAt: existingCategoryBudget(id: budgetID)?.createdAt ?? .now,
            updatedAt: .now,
            isActive: isActive
        )

        print("Saving category budget:", resolvedCategory.displayName, cadence.rawValue, limit)
        if let budgetID, let index = categoryBudgets.firstIndex(where: { $0.id == budgetID }) {
            categoryBudgets[index] = sanitizedBudget
        } else if let index = categoryBudgets.firstIndex(where: { $0.storageKey == sanitizedBudget.storageKey }) {
            categoryBudgets[index] = sanitizedBudget
        } else {
            categoryBudgets.append(sanitizedBudget)
        }

        persistCategoryBudgets()
    }

    func removeCategoryBudget(id: UUID) {
        print("Removing category budget:", id)
        categoryBudgets.removeAll { $0.id == id }
        persistCategoryBudgets()
    }

    func saveRecurringExpense(
        recurringID: UUID? = nil,
        merchant: String,
        amount: Double,
        category: ExpenseCategory,
        cadence: RecurringExpenseCadence,
        nextDueDate: Date,
        isActive: Bool = true
    ) {
        guard amount.isFinite, amount > 0 else {
            print("Invalid recurring expense ignored:", amount)
            return
        }

        let normalizedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCategory = resolvedCategory(from: category)
        let sanitizedRecurring = RecurringExpense(
            id: recurringID ?? UUID(),
            merchant: normalizedMerchant,
            amount: amount,
            category: normalizedCategory,
            cadence: cadence,
            nextDueDate: nextDueDate,
            isActive: isActive,
            createdAt: existingRecurringExpense(id: recurringID)?.createdAt ?? .now,
            updatedAt: .now
        )

        guard sanitizedRecurring.isValid else {
            print("Invalid recurring expense ignored:", sanitizedRecurring)
            return
        }

        print("Saving recurring expense:", normalizedMerchant, cadence.rawValue, amount)
        if let recurringID, let index = recurringExpenses.firstIndex(where: { $0.id == recurringID }) {
            recurringExpenses[index] = sanitizedRecurring
        } else {
            recurringExpenses.append(sanitizedRecurring)
        }

        persistRecurringExpenses()
    }

    func removeRecurringExpense(id: UUID) {
        print("Removing recurring expense:", id)
        recurringExpenses.removeAll { $0.id == id }
        persistRecurringExpenses()
    }

    func markRecurringAsPaid(id: UUID) {
        guard let recurring = recurringExpenses.first(where: { $0.id == id && $0.isValid }) else { return }
        let expense = generateExpenseFromRecurring(recurring)
        expenses.insert(expense, at: 0)
        persistExpenses()

        guard let nextDueDate = recurring.nextOccurrenceFromStoredDate() else {
            recurringExpenses.removeAll { $0.id == id }
            persistRecurringExpenses()
            return
        }

        saveRecurringExpense(
            recurringID: recurring.id,
            merchant: recurring.merchant,
            amount: recurring.amount,
            category: recurring.category,
            cadence: recurring.cadence,
            nextDueDate: nextDueDate,
            isActive: recurring.isActive
        )
    }

    func generateExpenseFromRecurring(_ recurring: RecurringExpense) -> Expense {
        Expense(
            amount: recurring.amount,
            category: resolvedCategory(from: recurring.category),
            merchant: recurring.normalizedMerchant,
            note: "Recurring expense",
            date: recurring.nextDueDate,
            source: .manual,
            confidence: 1.0
        )
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

    func updatePrivacyPreferences(hideAmounts: Bool, hideAmountsInWidgets: Bool) {
        privacyModeHideAmounts = hideAmounts
        self.hideAmountsInWidgets = hideAmountsInWidgets
        syncWidgetSummary()
    }

    func expenses(matching category: ExpenseCategory?, timeFilter: HistoryTimeFilter) -> [Expense] {
        filteredExpenses(category: category, timeFilter: timeFilter)
            .sorted { $0.date > $1.date }
    }

    func filteredExpenses(using filter: ExpenseFilter) -> [Expense] {
        let matchingExpenses = safeExpenses.filter { filter.matches($0, calendar: calendar) }
        return filter.sortOrder.sorted(matchingExpenses)
    }

    func filteredExpenseCount(using filter: ExpenseFilter) -> Int {
        filteredExpenses(using: filter).count
    }

    func filteredExpenseTotal(using filter: ExpenseFilter) -> Double {
        filteredExpenses(using: filter).reduce(0) { $0 + $1.amount }
    }

    var availableMerchants: [String] {
        Array(
            Set(
                safeExpenses
                    .map { $0.merchant.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted { lhs, rhs in
            lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }
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
        safeExpenses.count
    }

    var expenseCountThisMonth: Int {
        expenses(in: .month).count
    }

    var averageExpenseAmount: Double {
        guard !safeExpenses.isEmpty else { return 0 }
        return totalAmount / Double(safeExpenses.count)
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
        safeExpenses.max(by: { $0.amount < $1.amount })
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

    var dashboardCategorySummariesSafe: [DashboardCategorySummary] {
        let monthExpenses = expenses(in: .month).filter { $0.amount.isFinite && $0.amount > 0 }
        guard !monthExpenses.isEmpty else { return [] }

        let grouped = Dictionary(grouping: monthExpenses, by: { normalizedCategoryKey(for: $0.category) })
        let total = monthExpenses.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }

        return grouped.compactMap { key, items in
            let validItems = items.filter { $0.amount.isFinite && $0.amount > 0 }
            guard !validItems.isEmpty else { return nil }
            let category = validItems.first?.category ?? items.first?.category
            guard let category else { return nil }

            let categoryTotal = validItems.reduce(0) { $0 + $1.amount }
            guard categoryTotal.isFinite, categoryTotal > 0 else { return nil }

            let percentage = clampPercentage(categoryTotal / total)
            guard percentage.isFinite else { return nil }

            return DashboardCategorySummary(
                key: key,
                categoryName: category.displayName,
                total: categoryTotal,
                count: validItems.count,
                percentage: percentage,
                accentColor: category.accentColor
            )
        }
        .sorted { lhs, rhs in
            if lhs.total == rhs.total {
                return lhs.categoryName < rhs.categoryName
            }
            return lhs.total > rhs.total
        }
    }

    var dashboardTrendPointsSafe: [DashboardTrendPoint] {
        let daysToShow = 14
        guard let startDate = calendar.date(byAdding: .day, value: -(daysToShow - 1), to: calendar.startOfDay(for: .now)) else {
            return []
        }

        let sourceExpenses = safeExpenses.filter { $0.amount > 0 && $0.amount.isFinite }
        let totalsByDay = Dictionary(
            grouping: sourceExpenses,
            by: { calendar.startOfDay(for: $0.date) }
        ).mapValues { items in
            items.reduce(0) { $0 + $1.amount }
        }

        return (0..<daysToShow).compactMap { index in
            guard let date = calendar.date(byAdding: .day, value: index, to: startDate) else {
                return nil
            }

            let total = totalsByDay[date] ?? 0
            guard total.isFinite, total >= 0 else { return nil }

            return DashboardTrendPoint(
                index: index,
                date: date,
                total: total
            )
        }
    }

    var dashboardTopCategorySafe: DashboardTopCategorySignal? {
        dashboardCategorySummariesSafe.first.map {
            DashboardTopCategorySignal(
                key: $0.key,
                categoryName: $0.categoryName,
                total: $0.total,
                percentage: $0.percentage,
                count: $0.count,
                accentColor: $0.accentColor
            )
        }
    }

    var dashboardSignalSafe: DashboardSignal? {
        let strings = AppStrings.current()

        if let overview = primaryCategoryBudgetOverview {
            let cadenceLabel = overview.budget.cadence == .weekly
                ? strings.categoryBudgetsWeeklyLabel
                : strings.categoryBudgetsMonthlyLabel

            let detail = String(
                format: strings.categoryBudgetInsightTemplate,
                overview.budget.category.displayName,
                overview.percentUsedText,
                cadenceLabel
            )

            return DashboardSignal(
                id: "budget-\(overview.id.uuidString)",
                kind: .budget,
                title: overview.budget.category.displayName,
                detail: detail,
                accentColor: overview.status.tintColor
            )
        }

        guard let top = dashboardTopCategorySafe else { return nil }
        let detail = "\(currency(top.total)) • \(percentageString(top.percentage)) of month"

        return DashboardSignal(
            id: "top-\(top.id)",
            kind: .topCategory,
            title: top.categoryName,
            detail: detail,
            accentColor: top.accentColor
        )
    }

    var dashboardCategoryBudgetSignalSafe: DashboardCategoryBudgetSignal? {
        guard let overview = primaryCategoryBudgetOverview else { return nil }
        let cadenceText = overview.budget.cadence == .weekly
            ? AppStrings.current().categoryBudgetsWeeklyLabel
            : AppStrings.current().categoryBudgetsMonthlyLabel

        return DashboardCategoryBudgetSignal(
            id: overview.id.uuidString,
            categoryName: overview.budget.category.displayName,
            cadenceText: cadenceText,
            spentText: currency(overview.spent),
            limitText: currency(overview.budget.limit),
            remainingText: currency(overview.remaining),
            percentText: overview.percentUsedText,
            progressFraction: clampPercentage(overview.progressFraction),
            statusText: categoryBudgetStatusText(for: overview.status),
            accentColor: overview.status.tintColor
        )
    }

    var dashboardRecurringSignalSafe: DashboardRecurringSignal? {
        guard let recurring = nextRecurringExpense,
              recurring.amount.isFinite,
              recurring.amount > 0,
              recurring.nextDueDate.timeIntervalSinceReferenceDate.isFinite else {
            return nil
        }

        let merchant = recurring.normalizedMerchant.isEmpty ? recurring.category.displayName : recurring.normalizedMerchant
        let cadenceText = recurringExpenseCadenceText(for: recurring.cadence)

        return DashboardRecurringSignal(
            id: recurring.id,
            merchant: merchant,
            amountText: currency(recurring.amount),
            categoryName: recurring.category.displayName,
            dueDateText: recurring.nextDueDate.formatted(date: .abbreviated, time: .omitted),
            cadenceText: cadenceText,
            accentColor: recurring.category.accentColor
        )
    }

    var dashboardSmartInsightSafe: DashboardSmartInsight? {
        let monthExpenses = expenses(in: .month).filter { $0.amount.isFinite && $0.amount > 0 }
        guard !monthExpenses.isEmpty else { return nil }

        if let budget = dashboardCategoryBudgetSignalSafe, budget.progressFraction >= 0.75 {
            let title = AppStrings.current().dashboardSmartInsightTitle
            let message = String(
                format: AppStrings.current().categoryBudgetInsightTemplate,
                budget.categoryName,
                budget.percentText,
                budget.cadenceText
            )

            return DashboardSmartInsight(
                id: "budget-\(budget.id)",
                title: title,
                message: message,
                symbolName: budget.progressFraction >= 1 ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill",
                accentColor: budget.accentColor
            )
        }

        let thisWeekTotal = expenses(in: .week).reduce(0) { $0 + $1.amount }
        let previousWeekStart = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: .now)) ?? .now
        let previousWeekEnd = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: .now)) ?? .now
        let previousWeekTotal = safeExpenses.filter { expense in
            expense.amount.isFinite
                && expense.amount > 0
                && expense.date >= previousWeekStart
                && expense.date <= previousWeekEnd
        }.reduce(0) { $0 + $1.amount }

        if previousWeekTotal > 0, thisWeekTotal.isFinite, previousWeekTotal.isFinite {
            let delta = thisWeekTotal - previousWeekTotal
            let title = AppStrings.current().dashboardSmartInsightTitle
            if delta > 0 {
                return DashboardSmartInsight(
                    id: "trend-up",
                    title: title,
                    message: String(format: AppStrings.current().smartInsightsSpendingIncreaseMessage, currency(delta), percentageString((delta / max(previousWeekTotal, 1)) * 100)),
                    symbolName: "arrow.up.right",
                    accentColor: Color(red: 0.86, green: 0.25, blue: 0.24)
                )
            } else if delta < 0 {
                let saved = abs(delta)
                return DashboardSmartInsight(
                    id: "trend-down",
                    title: title,
                    message: String(format: AppStrings.current().smartInsightsSpendingDecreaseMessage, currency(saved), percentageString((saved / max(previousWeekTotal, 1)) * 100)),
                    symbolName: "arrow.down.right",
                    accentColor: Color(red: 0.19, green: 0.64, blue: 0.38)
                )
            }
        }

        if let top = dashboardTopCategorySafe, top.percentage.isFinite, top.percentage > 0 {
            return DashboardSmartInsight(
                id: "top-\(top.id)",
                title: AppStrings.current().dashboardSmartInsightTitle,
                message: "\(top.categoryName) is \(percentageString(top.percentage)) of your tracked leaks this month.",
                symbolName: "chart.pie.fill",
                accentColor: top.accentColor
            )
        }

        let avgDaily = averageDailySpend
        guard avgDaily.isFinite, avgDaily > 0 else { return nil }

        return DashboardSmartInsight(
            id: "avg-daily",
            title: AppStrings.current().dashboardSmartInsightTitle,
            message: "You are averaging \(currency(avgDaily)) per day this month.",
            symbolName: "calendar",
            accentColor: Color(red: 0.18, green: 0.47, blue: 0.88)
        )
    }

    var recentSpendTrendData: [DailySpendPoint] {
        let daysToShow = 14
        guard let startDate = calendar.date(byAdding: .day, value: -(daysToShow - 1), to: calendar.startOfDay(for: .now)) else {
            return []
        }

        let totalsByDay = Dictionary(
            grouping: safeExpenses,
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
            grouping: safeExpenses,
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
            safeExpenses.compactMap { expense in
                calendar.dateInterval(of: .weekOfYear, for: expense.date)?.start
            }
        ).count >= 2
    }

    var insightText: String {
        if let primarySmartInsight {
            return primarySmartInsight.message
        }

        guard let topCategory else {
            return "Add your first micro-expense to see a spending pattern."
        }

        return "\(topCategory.displayName) is your top micro-expense category this month."
    }

    var primarySmartInsight: SmartInsight? {
        smartInsights.first(where: { $0.type != .neutral })
    }

    var primarySmartAlert: SmartAlert? {
        smartAlerts.first
    }

    var primarySpendingComparison: SpendingComparison? {
        spendingComparisons.first(where: { $0.period == .weekVsLastWeek && $0.hasPreviousData })
            ?? spendingComparisons.first(where: { $0.hasPreviousData })
            ?? spendingComparisons.first
    }

    var primaryGoalForecast: GoalForecast? {
        goalForecasts.first(where: { $0.goalType == .monthly && $0.status != .safe })
            ?? goalForecasts.first(where: { $0.goalType == .weekly && $0.status != .safe })
            ?? goalForecasts.sorted { forecastPriority(lhs: $0, rhs: $1) }.first(where: { $0.status != .safe })
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

    var pdfExportSnapshotSignature: String {
        let expenseSignature = safeExpenses
            .map { "\($0.id.uuidString):\($0.amount):\($0.date.timeIntervalSince1970):\($0.category.id.uuidString):\($0.merchant):\($0.note)" }
            .joined(separator: ",")

        return [
            AppLanguage.current.rawValue,
            String(safeExpenses.count),
            String(format: "%.2f", totalAmount),
            String(format: "%.2f", weekTotal),
            String(format: "%.2f", monthTotal),
            expenseSignature,
            weeklyGoal.map { "\($0.limit)-\($0.updatedAt.timeIntervalSince1970)" } ?? "no-weekly-goal",
            monthlyGoal.map { "\($0.limit)-\($0.updatedAt.timeIntervalSince1970)" } ?? "no-monthly-goal",
            smartInsights.first?.id.uuidString ?? "no-insight",
            smartAlerts.first?.id ?? "no-alert",
            weeklyDigest.id.timeIntervalSince1970.description
        ]
        .joined(separator: "|")
    }

    func pdfReportData(for reportType: ExpensePDFReportType) -> ExpensePDFReportData {
        pdfReportData(for: reportType, expenses: pdfExpenses(for: reportType))
    }

    func pdfReportData(for reportType: ExpensePDFReportType, expenses: [Expense]) -> ExpensePDFReportData {
        let strings = AppStrings.current()
        let reportExpenses = expenses
        let breakdown = categoryBreakdown(from: reportExpenses, sortMode: .amount)
        let goalSummaries = goalOverviews.map { overview in
            ExpensePDFGoalSummary(
                title: overview.cadence == .weekly ? strings.goalsWeeklyTitle : strings.goalsMonthlyTitle,
                spent: overview.spent,
                remaining: overview.remaining,
                limit: overview.goal.limit,
                statusText: overview.statusText,
                motivationText: overview.motivationText
            )
        }
        let insights = smartInsights
            .sorted { $0.priority > $1.priority }
            .prefix(3)
            .map { insight in
                ExpensePDFInsightSummary(
                    title: insight.title,
                    message: insight.message,
                    type: insight.type
                )
            }

        return ExpensePDFReportData(
            reportType: reportType,
            reportTitle: strings.pdfReportTitle,
            reportTypeLabel: pdfReportTypeLabel(for: reportType, strings: strings),
            periodLabel: pdfReportPeriodLabel(for: reportType, strings: strings),
            exportedOnLabel: strings.pdfExportedOn,
            totalSpentLabel: strings.pdfTotalSpent,
            expenseCountLabel: strings.pdfExpenseCount,
            topCategoryLabel: strings.pdfTopCategory,
            categoryBreakdownLabel: strings.pdfCategoryBreakdown,
            goalSummaryLabel: strings.pdfGoalSummary,
            smartInsightsLabel: strings.pdfSmartInsights,
            recentExpensesLabel: strings.pdfRecentExpenses,
            emptyStateMessage: strings.pdfNoDataMessage,
            footerText: strings.pdfGeneratedByFooter,
            generatedAt: .now,
            totalSpent: reportExpenses.reduce(0) { $0 + $1.amount },
            expenseCount: reportExpenses.count,
            topCategory: breakdown.first?.category,
            categoryBreakdown: breakdown.map {
                ExpensePDFCategorySummary(category: $0.category, total: $0.total, count: $0.count)
            },
            goalSummaries: goalSummaries,
            smartInsights: insights,
            recentExpenses: reportExpenses.sorted { $0.date > $1.date }
        )
    }

    func shareCardModel(for variant: ShareCardVariant, strings: AppStrings) -> ShareCardModel? {
        switch variant {
        case .weeklySummary:
            return weeklyShareCardModel(strings: strings)
        case .monthlySummary:
            return monthlyShareCardModel(strings: strings)
        case .goalProgress:
            return goalShareCardModel(strings: strings)
        case .topCategory:
            return topCategoryShareCardModel(strings: strings)
        }
    }

    var shareCardSnapshotSignature: String {
        [
            String(safeExpenses.count),
            String(format: "%.2f", todayTotal),
            String(format: "%.2f", weekTotal),
            String(format: "%.2f", monthTotal),
            weeklyGoal.map { "\($0.limit)-\($0.updatedAt.timeIntervalSince1970)" } ?? "no-weekly-goal",
            monthlyGoal.map { "\($0.limit)-\($0.updatedAt.timeIntervalSince1970)" } ?? "no-monthly-goal",
            topCategory?.id.uuidString ?? "no-top-category",
            primaryGoalForecast?.id.rawValue ?? "no-goal-forecast"
        ]
        .joined(separator: "|")
    }

    func goal(for cadence: SpendingGoalCadence) -> SpendingGoal? {
        switch cadence {
        case .weekly:
            return weeklyGoal?.isValid == true ? weeklyGoal : nil
        case .monthly:
            return monthlyGoal?.isValid == true ? monthlyGoal : nil
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
        let spent = goalSpentAmount(for: cadence)
        guard spent.isFinite else { return 0 }
        let remaining = goal.limit - spent
        return remaining.isFinite ? max(remaining, 0) : 0
    }

    func goalPercentUsed(for cadence: SpendingGoalCadence) -> Double {
        guard let goal = goal(for: cadence), goal.limit > 0 else { return 0 }
        let spent = goalSpentAmount(for: cadence)
        guard spent.isFinite else { return 0 }
        let percent = (spent / goal.limit) * 100
        return percent.isFinite ? min(percent, 999) : 0
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
        let spent = goalSpentAmount(for: cadence)
        guard spent.isFinite else { return 0 }
        let fraction = spent / goal.limit
        return fraction.isFinite ? min(fraction, 1) : 0
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

        guard spent.isFinite, remaining.isFinite, percentUsed.isFinite else {
            return nil
        }

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

    func goalForecast(for cadence: SpendingGoalCadence) -> GoalForecast? {
        goalForecasts.first(where: { $0.goalType == cadence })
    }

    func goalForecastStatusText(for cadence: SpendingGoalCadence) -> String {
        guard let forecast = goalForecast(for: cadence) else {
            return goalStatusText(for: cadence)
        }

        let strings = AppStrings.current()
        switch forecast.status {
        case .safe:
            return strings.goalForecastStatusSafe
        case .watch:
            return strings.goalForecastStatusWatch
        case .risk:
            return strings.goalForecastStatusRisk
        case .over:
            return strings.goalForecastStatusOver
        }
    }

    func goalForecastSummaryText(for cadence: SpendingGoalCadence) -> String? {
        guard let forecast = goalForecast(for: cadence) else { return nil }
        let strings = AppStrings.current()
        let paceText = String(format: strings.goalsForecastAtThisPaceTemplate, currency(forecast.projectedSpend))
        let dailyBudgetText = String(format: strings.goalsForecastDailyBudgetTemplate, currency(forecast.remainingDailyBudget))
        let varianceText: String

        if forecast.status == .over {
            varianceText = String(
                format: strings.goalsForecastOverSummary,
                currency(forecast.projectedOverLimitAmount)
            )
        } else if forecast.projectedOverLimitAmount > 0 {
            varianceText = String(
                format: strings.goalsForecastGoOverTemplate,
                currency(forecast.projectedOverLimitAmount)
            )
        } else {
            varianceText = String(
                format: strings.goalsForecastStayUnderTemplate,
                currency(forecast.projectedUnderLimitAmount)
            )
        }

        return [
            paceText,
            dailyBudgetText,
            varianceText
        ]
        .joined(separator: " • ")
    }

    func goalForecastStatusColor(for cadence: SpendingGoalCadence) -> Color {
        guard let forecast = goalForecast(for: cadence) else {
            return Color(red: 0.19, green: 0.64, blue: 0.38)
        }

        return forecast.status.tintColor
    }

    func goalForecastHeadline(for cadence: SpendingGoalCadence) -> String? {
        guard let forecast = goalForecast(for: cadence) else { return nil }
        let strings = AppStrings.current()
        let cadenceTitle = cadence == .weekly ? strings.goalsWeeklyTitle : strings.goalsMonthlyTitle
        let label = String(format: strings.dashboardGoalAtRiskTitleTemplate, cadenceTitle)
        switch forecast.status {
        case .safe:
            return nil
        case .watch, .risk, .over:
            return label
        }
    }

    func goalForecastHelperText(for cadence: SpendingGoalCadence) -> String? {
        guard let forecast = goalForecast(for: cadence) else { return nil }
        let strings = AppStrings.current()
        return String(format: strings.dashboardGoalAtRiskSubtitleTemplate, currency(forecast.remainingDailyBudget))
    }

    func goalAccessibilityValue(for cadence: SpendingGoalCadence) -> String {
        guard let overview = goalOverview(for: cadence) else {
            return AppStrings.current().goalsNoGoalMessage
        }

        let limitText = displayCurrency(overview.goal.limit)
        let spentText = displayCurrency(overview.spent)
        let remainingText = displayCurrency(overview.remaining)

        return [
            limitText,
            spentText,
            remainingText,
            overview.percentUsedText,
            overview.statusText,
            privacyAwareText(overview.motivationText)
        ]
        .joined(separator: ". ")
    }

    func expenseAccessibilitySummary(for expense: Expense) -> String {
        let merchant = expense.merchant.isEmpty ? expense.category.displayName : expense.merchant
        let note = expense.note.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteText = note.isEmpty ? "" : ". Note: \(note)"
        return "\(displayCurrency(expense.amount)) in \(expense.category.displayName). Merchant: \(merchant). \(expense.date.formatted(date: .abbreviated, time: .shortened))\(noteText)"
    }

    var goalOverviews: [GoalOverview] {
        [goalOverview(for: .weekly), goalOverview(for: .monthly)].compactMap { $0 }
    }

    var activeCategoryBudgets: [CategoryBudget] {
        categoryBudgets.filter { $0.isActive && $0.isValid }
    }

    var categoryBudgetOverviews: [CategoryBudgetOverview] {
        activeCategoryBudgets.compactMap { categoryBudgetOverview(for: $0) }
            .sorted { lhs, rhs in
                if lhs.percentUsed == rhs.percentUsed {
                    return lhs.budget.updatedAt > rhs.budget.updatedAt
                }
                return lhs.percentUsed > rhs.percentUsed
            }
    }

    var primaryCategoryBudgetOverview: CategoryBudgetOverview? {
        categoryBudgetOverviews.first
    }

    var activeRecurringExpenses: [RecurringExpense] {
        recurringExpenses.filter { $0.isActive && $0.isValid }
    }

    var upcomingRecurringExpenses: [RecurringExpense] {
        activeRecurringExpenses.sorted { lhs, rhs in
            if lhs.nextDueDate == rhs.nextDueDate {
                return lhs.updatedAt > rhs.updatedAt
            }
            return lhs.nextDueDate < rhs.nextDueDate
        }
    }

    var nextRecurringExpense: RecurringExpense? {
        upcomingRecurringExpenses.first
    }

    var upcomingRecurringLeakSummaryText: String {
        guard let nextRecurringExpense else {
            return AppStrings.current().recurringExpensesNoUpcomingMessage
        }

        let strings = AppStrings.current()
        let dueDate = nextRecurringExpense.nextDueDate.formatted(date: .abbreviated, time: .omitted)
        let merchant = nextRecurringExpense.normalizedMerchant.isEmpty
            ? nextRecurringExpense.category.displayName
            : nextRecurringExpense.normalizedMerchant

        return String(
            format: strings.recurringExpensesUpcomingSummaryTemplate,
            merchant,
            currency(nextRecurringExpense.amount),
            dueDate
        )
    }

    func categoryBudget(for category: ExpenseCategory, cadence: SpendingGoalCadence) -> CategoryBudget? {
        categoryBudgets.first { budget in
            budget.isActive
                && budget.isValid
                && budget.category.id == category.id
                && budget.cadence == cadence
        }
    }

    func categoryBudgetSpentAmount(for budget: CategoryBudget) -> Double {
        categoryBudgetExpenses(for: budget).reduce(0) { $0 + $1.amount }
    }

    func categoryBudgetRemainingAmount(for budget: CategoryBudget) -> Double {
        guard budget.limit.isFinite, budget.limit > 0 else { return 0 }
        let spent = categoryBudgetSpentAmount(for: budget)
        guard spent.isFinite else { return 0 }
        let remaining = budget.limit - spent
        return remaining.isFinite ? max(remaining, 0) : 0
    }

    func categoryBudgetPercentUsed(for budget: CategoryBudget) -> Double {
        guard budget.limit.isFinite, budget.limit > 0 else { return 0 }
        let spent = categoryBudgetSpentAmount(for: budget)
        guard spent.isFinite else { return 0 }
        let percent = (spent / budget.limit) * 100
        return percent.isFinite ? min(percent, 999) : 0
    }

    func categoryBudgetProgressFraction(for budget: CategoryBudget) -> Double {
        guard budget.limit.isFinite, budget.limit > 0 else { return 0 }
        let spent = categoryBudgetSpentAmount(for: budget)
        guard spent.isFinite else { return 0 }
        let fraction = spent / budget.limit
        return fraction.isFinite ? min(fraction, 1) : 0
    }

    func categoryBudgetStatus(for budget: CategoryBudget) -> CategoryBudgetStatus {
        switch categoryBudgetPercentUsed(for: budget) {
        case 100...:
            return .over
        case 75..<100:
            return .watch
        default:
            return .safe
        }
    }

    func categoryBudgetStatusText(for budget: CategoryBudget) -> String {
        categoryBudgetStatusText(for: categoryBudgetStatus(for: budget))
    }

    func categoryBudgetStatusText(for status: CategoryBudgetStatus) -> String {
        let strings = AppStrings.current()
        switch status {
        case .safe:
            return strings.categoryBudgetsStatusSafe
        case .watch:
            return strings.categoryBudgetsStatusWatch
        case .over:
            return strings.categoryBudgetsStatusOver
        }
    }

    func categoryBudgetOverview(for budget: CategoryBudget) -> CategoryBudgetOverview? {
        guard budget.isActive, budget.isValid else { return nil }
        let spent = categoryBudgetSpentAmount(for: budget)
        let remaining = categoryBudgetRemainingAmount(for: budget)
        let percentUsed = categoryBudgetPercentUsed(for: budget)
        let progressFraction = categoryBudgetProgressFraction(for: budget)
        guard spent.isFinite, remaining.isFinite, percentUsed.isFinite, progressFraction.isFinite else {
            return nil
        }

        return CategoryBudgetOverview(
            budget: budget,
            spent: spent,
            remaining: remaining,
            percentUsed: percentUsed,
            progressFraction: progressFraction,
            status: categoryBudgetStatus(for: budget)
        )
    }

    func categoryBudgetInsightText(for overview: CategoryBudgetOverview) -> String {
        let strings = AppStrings.current()
        let cadenceLabel = overview.budget.cadence == .weekly ? strings.categoryBudgetsWeeklyLabel : strings.categoryBudgetsMonthlyLabel
        return String(
            format: strings.categoryBudgetInsightTemplate,
            overview.budget.category.displayName,
            overview.percentUsedText,
            cadenceLabel
        )
    }

    func categoryBudgetAccessibilityValue(for budget: CategoryBudget) -> String {
        guard let overview = categoryBudgetOverview(for: budget) else {
            return AppStrings.current().categoryBudgetsEmptyMessage
        }

        return [
            displayCurrency(overview.budget.limit),
            displayCurrency(overview.spent),
            displayCurrency(overview.remaining),
            overview.percentUsedText,
            categoryBudgetStatusText(for: overview.status)
        ]
        .joined(separator: ". ")
    }

    func recurringExpenseTitle(for expense: RecurringExpense) -> String {
        expense.normalizedMerchant.isEmpty ? expense.category.displayName : expense.normalizedMerchant
    }

    func recurringExpenseCadenceText(for cadence: RecurringExpenseCadence) -> String {
        let strings = AppStrings.current()
        switch cadence {
        case .daily:
            return strings.recurringCadenceDaily
        case .weekly:
            return strings.recurringCadenceWeekly
        case .monthly:
            return strings.recurringCadenceMonthly
        case .yearly:
            return strings.recurringCadenceYearly
        }
    }

    func recurringExpenseNextDueText(for expense: RecurringExpense) -> String {
        let date = expense.nextDueDate.formatted(date: .abbreviated, time: .omitted)
        return String(format: AppStrings.current().recurringExpensesNextDueTemplate, date)
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

    func csvExport(for expenses: [Expense]) -> ExpenseCSVExport {
        ExpenseCSVExport(expenses: expenses)
    }

    func jsonExport(for expenses: [Expense]) -> ExpenseJSONExport {
        ExpenseJSONExport(expenses: expenses)
    }

    private var safeExpenses: [Expense] {
        expenses.filter { $0.amount.isFinite }
    }

    private var totalAmount: Double {
        safeExpenses.reduce(0) { $0 + $1.amount }
    }

    private func filteredExpenses(category: ExpenseCategory?, timeFilter: HistoryTimeFilter) -> [Expense] {
        safeExpenses.filter { expense in
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
        safeExpenses.filter { expense in
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
        categoryBreakdown(from: expenses(in: .month), sortMode: sortMode)
    }

    private func categoryBreakdown(in range: TimeRange, sortMode: CategorySortMode) -> [CategoryBreakdown] {
        categoryBreakdown(from: expenses(in: range), sortMode: sortMode)
    }

    private func categoryBreakdown(from sourceExpenses: [Expense], sortMode: CategorySortMode) -> [CategoryBreakdown] {
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

    private func normalizedCategoryKey(for category: ExpenseCategory) -> String {
        category.slug.isEmpty ? category.displayName.lowercased() : category.slug
    }

    private func clampPercentage(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }

    private func categoryBudgetExpenses(for budget: CategoryBudget) -> [Expense] {
        let range: TimeRange = budget.cadence == .weekly ? .week : .month
        return expenses(in: range).filter { $0.category.id == budget.category.id }
    }

    private func pdfExpenses(for reportType: ExpensePDFReportType) -> [Expense] {
        switch reportType {
        case .weekly:
            return expenses(in: .week).sorted { $0.date > $1.date }
        case .monthly:
            return expenses(in: .month).sorted { $0.date > $1.date }
        case .allData:
            return safeExpenses.sorted { $0.date > $1.date }
        }
    }

    private func pdfReportTypeLabel(for reportType: ExpensePDFReportType, strings: AppStrings) -> String {
        switch reportType {
        case .weekly:
            return strings.pdfWeeklyReportTitle
        case .monthly:
            return strings.pdfMonthlyReportTitle
        case .allData:
            return strings.pdfAllDataReportTitle
        }
    }

    private func pdfReportPeriodLabel(for reportType: ExpensePDFReportType, strings: AppStrings) -> String {
        switch reportType {
        case .weekly:
            return strings.goalsPeriodThisWeek
        case .monthly:
            return strings.goalsPeriodThisMonth
        case .allData:
            return strings.pdfAllDataPeriod
        }
    }

    private func categoryShares(in range: TimeRange) -> [CategoryShare] {
        let breakdown = categoryBreakdown(in: range, sortMode: .amount)
        let total = expenses(in: range).reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }

        return breakdown.map { item in
            CategoryShare(
                category: item.category,
                total: item.total,
                count: item.count,
                percentage: (item.total / total) * 100
            )
        }
    }

    private func topCategoryShare(in range: TimeRange) -> CategoryShare? {
        categoryShares(in: range).first
    }

    private func shareCardMessage(for variant: ShareCardVariant, cadence: SpendingGoalCadence?, strings: AppStrings) -> String {
        switch variant {
        case .weeklySummary:
            return strings.shareSummaryWeeklyMessage
        case .monthlySummary:
            return strings.shareSummaryMonthlyMessage
        case .goalProgress:
            guard let cadence else { return strings.shareSummaryGoalMessage }
            guard let forecast = goalForecast(for: cadence) else { return strings.shareSummaryGoalMessage }

            switch forecast.status {
            case .safe:
                return String(format: strings.goalsForecastDailyBudgetTemplate, currency(forecast.remainingDailyBudget))
            case .watch:
                return String(format: strings.goalsForecastAtThisPaceTemplate, currency(forecast.projectedSpend))
            case .risk:
                return String(format: strings.goalsForecastGoOverTemplate, currency(forecast.projectedOverLimitAmount))
            case .over:
                return String(format: strings.goalsForecastOverSummary, currency(forecast.projectedOverLimitAmount))
            }
        case .topCategory:
            return strings.shareSummaryTopCategoryMessage
        }
    }

    private func weeklyShareCardModel(strings: AppStrings) -> ShareCardModel? {
        guard !expenses.isEmpty || hasWeeklyGoal else { return nil }
        let topShare = topCategoryShare(in: .week)
        let goalStatus = goalStatusText(for: .weekly)
        var chips: [ShareCardChip] = []

        if let topShare {
            chips.append(ShareCardChip(title: "\(strings.shareSummaryTopCategoryChipPrefix) \(topShare.category.displayName)", tint: topShare.category.accentColor))
        }

        if hasWeeklyGoal {
            chips.append(ShareCardChip(title: "\(strings.goalsWeeklyTitle): \(goalStatus)", tint: goalForecastStatusColor(for: .weekly)))
        }

        return ShareCardModel(
            variant: .weeklySummary,
            badgeLabel: strings.shareSummaryBadgeWeekly,
            title: strings.shareSummaryWeeklyCardTitle,
            periodLabel: strings.goalsPeriodThisWeek,
            bigValueLabel: currency(weekTotal),
            accentColor: topShare?.category.accentColor ?? Color(red: 0.18, green: 0.47, blue: 0.88),
            symbolName: "calendar",
            chips: chips,
            message: shareCardMessage(for: .weeklySummary, cadence: .weekly, strings: strings)
        )
    }

    private func monthlyShareCardModel(strings: AppStrings) -> ShareCardModel? {
        guard !expenses.isEmpty || hasMonthlyGoal else { return nil }
        let topShare = topCategoryShare(in: .month)
        let goalStatus = goalStatusText(for: .monthly)
        var chips: [ShareCardChip] = []

        if let topShare {
            chips.append(ShareCardChip(title: "\(strings.shareSummaryTopCategoryChipPrefix) \(topShare.category.displayName)", tint: topShare.category.accentColor))
        }

        if hasMonthlyGoal {
            chips.append(ShareCardChip(title: "\(strings.goalsMonthlyTitle): \(goalStatus)", tint: goalForecastStatusColor(for: .monthly)))
        }

        return ShareCardModel(
            variant: .monthlySummary,
            badgeLabel: strings.shareSummaryBadgeMonthly,
            title: strings.shareSummaryMonthlyCardTitle,
            periodLabel: strings.goalsPeriodThisMonth,
            bigValueLabel: currency(monthTotal),
            accentColor: topShare?.category.accentColor ?? Color(red: 0.86, green: 0.35, blue: 0.65),
            symbolName: "calendar.badge.clock",
            chips: chips,
            message: shareCardMessage(for: .monthlySummary, cadence: .monthly, strings: strings)
        )
    }

    private func goalShareCardModel(strings: AppStrings) -> ShareCardModel? {
        guard let cadence = goalCardCadence else { return nil }
        guard goal(for: cadence) != nil else { return nil }
        let spent = goalSpentAmount(for: cadence)
        let remaining = goalRemainingAmount(for: cadence)
        let statusColor = goalForecastStatusColor(for: cadence)
        let statusText = goalStatusText(for: cadence)
        let topShare = topCategoryShare(in: cadence == .weekly ? .week : .month)

        var chips: [ShareCardChip] = [
            ShareCardChip(title: "\(strings.goalsSpentLabel) \(currency(spent))", tint: AppTheme.primaryText),
            ShareCardChip(title: "\(strings.goalsRemainingLabel) \(currency(remaining))", tint: AppTheme.tertiaryText),
            ShareCardChip(title: statusText, tint: statusColor)
        ]

        if let topShare {
            chips.append(ShareCardChip(title: "\(strings.shareSummaryTopCategoryChipPrefix) \(topShare.category.displayName)", tint: topShare.category.accentColor))
        }

        return ShareCardModel(
            variant: .goalProgress,
            badgeLabel: strings.shareSummaryBadgeGoal,
            title: strings.shareSummaryGoalCardTitle,
            periodLabel: cadence == .weekly ? strings.goalsWeeklyTitle : strings.goalsMonthlyTitle,
            bigValueLabel: currency(spent),
            accentColor: statusColor,
            symbolName: "target",
            chips: chips,
            message: shareCardMessage(for: .goalProgress, cadence: cadence, strings: strings)
        )
    }

    private func topCategoryShareCardModel(strings: AppStrings) -> ShareCardModel? {
        guard let topShare = topCategoryShare(in: .month) else { return nil }
        var chips: [ShareCardChip] = [
            ShareCardChip(title: String(format: strings.shareSummaryTopCategoryShareTemplate, percentageString(topShare.percentage)), tint: topShare.category.accentColor),
            ShareCardChip(title: String(format: strings.shareSummaryTopCategoryCountTemplate, topShare.count), tint: AppTheme.primaryText)
        ]

        if hasMonthlyGoal {
            chips.append(ShareCardChip(title: "\(strings.goalsMonthlyTitle): \(goalStatusText(for: .monthly))", tint: goalForecastStatusColor(for: .monthly)))
        }

        return ShareCardModel(
            variant: .topCategory,
            badgeLabel: strings.shareSummaryBadgeTopCategory,
            title: strings.shareSummaryTopCategoryCardTitle,
            periodLabel: strings.goalsPeriodThisMonth,
            bigValueLabel: currency(topShare.total),
            accentColor: topShare.category.accentColor,
            symbolName: topShare.category.symbolName,
            chips: chips,
            message: shareCardMessage(for: .topCategory, cadence: .monthly, strings: strings)
        )
    }

    private var goalCardCadence: SpendingGoalCadence? {
        if let forecastCadence = primaryGoalForecast?.goalType {
            return forecastCadence
        }
        if monthlyGoal != nil {
            return .monthly
        }
        if weeklyGoal != nil {
            return .weekly
        }
        return nil
    }

    private func persistExpenses(refreshDerivedState: Bool = true) {
        let sanitizedExpenses = safeExpenses
        if sanitizedExpenses.count != expenses.count {
            expenses = sanitizedExpenses
        }
        store.saveExpenses(sanitizedExpenses)
        expenses = store.loadExpenses().filter { $0.amount.isFinite }
        guard refreshDerivedState else { return }
        refreshDerivedDataAfterMutation()
    }

    private func persistGoals(refreshDerivedState: Bool = true) {
        let sanitizedGoals = SpendingGoals(weekly: weeklyGoal, monthly: monthlyGoal).sanitized
        goalStore.saveGoals(sanitizedGoals)
        let savedGoals = goalStore.loadGoals().sanitized
        weeklyGoal = savedGoals.weekly
        monthlyGoal = savedGoals.monthly

        guard refreshDerivedState else {
            return
        }
        refreshDerivedDataAfterMutation()
    }

    private func persistCategoryBudgets() {
        let sanitizedBudgets = categoryBudgets.filter { $0.isValid }
        if sanitizedBudgets.count != categoryBudgets.count {
            categoryBudgets = sanitizedBudgets
        }
        categoryBudgetStore.saveBudgets(sanitizedBudgets)
        categoryBudgets = categoryBudgetStore.loadBudgets()
    }

    private func persistRecurringExpenses() {
        let sanitizedRecurring = recurringExpenses.filter { $0.isValid }
        if sanitizedRecurring.count != recurringExpenses.count {
            recurringExpenses = sanitizedRecurring
        }
        recurringExpenseStore.saveRecurringExpenses(sanitizedRecurring)
        recurringExpenses = recurringExpenseStore.loadRecurringExpenses()
    }

    private func refreshDerivedDataAfterMutation() {
        refreshGoalForecasts()
        refreshSpendingComparisons()
        refreshSmartInsights()
        refreshSmartAlerts()
        refreshWeeklyDigest()
        syncWidgetSummary()
        syncLocalNotifications()
    }

    private func mergeExpenses(current: [Expense], imported: [Expense]) -> [Expense] {
        var mergedByID: [UUID: Expense] = [:]
        current.forEach { mergedByID[$0.id] = $0 }

        for expense in imported {
            if mergedByID[expense.id] == nil {
                mergedByID[expense.id] = expense
            }
        }

        return mergedByID.values.sorted { $0.date > $1.date }
    }

    private func mergeCategoryBudgets(current: [CategoryBudget], imported: [CategoryBudget]) -> [CategoryBudget] {
        var mergedByKey: [String: CategoryBudget] = [:]
        current.forEach { mergedByKey[$0.storageKey] = $0 }

        for budget in imported {
            if let existing = mergedByKey[budget.storageKey] {
                if budget.updatedAt > existing.updatedAt {
                    mergedByKey[budget.storageKey] = budget
                }
            } else {
                mergedByKey[budget.storageKey] = budget
            }
        }

        return mergedByKey.values.sorted { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt {
                return lhs.category.displayName < rhs.category.displayName
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private func mergeRecurringExpenses(current: [RecurringExpense], imported: [RecurringExpense]) -> [RecurringExpense] {
        var mergedByID: [UUID: RecurringExpense] = [:]
        current.forEach { mergedByID[$0.id] = $0 }

        for recurring in imported {
            if let existing = mergedByID[recurring.id] {
                if recurring.updatedAt > existing.updatedAt {
                    mergedByID[recurring.id] = recurring
                }
            } else {
                mergedByID[recurring.id] = recurring
            }
        }

        return mergedByID.values.sorted { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt {
                return lhs.nextDueDate < rhs.nextDueDate
            }
            return lhs.updatedAt > rhs.updatedAt
        }
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

    func displayCurrency(_ amount: Double) -> String {
        guard !privacyModeHideAmounts else { return "••••" }
        return currency(amount)
    }

    func privacyAwareText(_ text: String) -> String {
        guard privacyModeHideAmounts else { return text }
        guard let regex = Self.currencyRedactionRegex else { return text }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "••••")
    }

    private func percentageString(_ value: Double) -> String {
        String(format: "%.0f%%", value)
    }

    private static let currencyRedactionRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "\\$\\d[\\d,]*(?:\\.\\d{1,2})?", options: [])
    }()

    private func applyParsedSuggestion(_ suggestion: ExpenseParseResult) {
        if let amount = suggestion.amount, amount.isFinite, amount > 0 {
            amountText = amountText(for: amount)
        }

        let resolvedMerchant = suggestion.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        if !resolvedMerchant.isEmpty {
            merchantText = resolvedMerchant
        }

        selectedCategory = resolvedCategory(from: suggestion.category)
        draftSource = suggestion.source
        draftConfidence = safeConfidence(suggestion.confidence)
    }

    private func parsedAmount(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(normalized), amount.isFinite, amount > 0 else {
            return nil
        }

        return amount
    }

    private func safeConfidence(_ value: Double) -> Double {
        guard value.isFinite else { return 1.0 }
        return min(max(value, 0), 1)
    }

    private func amountText(for amount: Double) -> String {
        if amount.rounded(.towardZero) == amount {
            return String(format: "%.0f", amount)
        }

        return String(format: "%.2f", amount)
    }

    private func resolvedCategory(from category: ExpenseCategory) -> ExpenseCategory {
        categories.first(where: { $0.id == category.id })
            ?? ExpenseCategory.category(matching: category.displayName, in: categories)
            ?? category
    }

    private func existingCategoryBudget(id: UUID?) -> CategoryBudget? {
        guard let id else { return nil }
        return categoryBudgets.first(where: { $0.id == id })
    }

    private func existingRecurringExpense(id: UUID?) -> RecurringExpense? {
        guard let id else { return nil }
        return recurringExpenses.first(where: { $0.id == id })
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
            weeklyGoalForecastText: widgetGoalForecastText(for: .weekly),
            monthlyGoalForecastText: widgetGoalForecastText(for: .monthly),
            categoryTop3: categoryBreakdown.prefix(3).map { WidgetCategorySummary(name: $0.category.displayName, amount: $0.total) },
            hideAmounts: hideAmountsInWidgets
        )

        widgetSummaryStore.saveSummary(summary)
    }

    private func refreshSmartInsights() {
        smartInsights = smartInsightsService.generateInsights(
            expenses: safeExpenses,
            goals: SpendingGoals(weekly: weeklyGoal, monthly: monthlyGoal),
            calendar: calendar,
            strings: AppStrings.current()
        )
    }

    private func refreshSmartAlerts() {
        smartAlerts = smartAlertService.generateAlerts(
            expenses: safeExpenses,
            goalForecasts: goalForecasts,
            comparisons: spendingComparisons,
            strings: AppStrings.current(),
            calendar: calendar
        )
    }

    private func refreshSpendingComparisons() {
        spendingComparisons = spendingComparisonService.generateComparisons(
            expenses: safeExpenses,
            calendar: calendar,
            strings: AppStrings.current()
        )
    }

    private func refreshWeeklyDigest() {
        weeklyDigest = weeklyDigestService.generateDigest(
            expenses: safeExpenses,
            goals: SpendingGoals(weekly: weeklyGoal, monthly: monthlyGoal),
            smartInsights: smartInsights,
            comparisons: spendingComparisons,
            calendar: calendar
        )
    }

    private func refreshGoalForecasts() {
        goalForecasts = goalIntelligenceService.generateForecasts(
            expenses: safeExpenses,
            goals: SpendingGoals(weekly: weeklyGoal, monthly: monthlyGoal),
            calendar: calendar
        )
    }

    func syncLocalNotifications() {
        let forecasts = goalForecasts
        Task { [localNotificationService] in
            await localNotificationService.syncRecurringNotifications()
            await localNotificationService.syncGoalWarnings(goalForecasts: forecasts)
        }
    }

    private func forecastPriority(lhs: GoalForecast, rhs: GoalForecast) -> Bool {
        if lhs.status.priority == rhs.status.priority {
            return lhs.goalType == .monthly && rhs.goalType == .weekly
        }
        return lhs.status.priority > rhs.status.priority
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

    private func widgetGoalForecastText(for cadence: SpendingGoalCadence) -> String? {
        guard let forecast = goalForecast(for: cadence) else { return nil }
        let strings = AppStrings.current()

        switch forecast.status {
        case .safe:
            return String(format: strings.goalsForecastDailyBudgetTemplate, currency(forecast.remainingDailyBudget))
        case .watch:
            return String(format: strings.goalsForecastAtThisPaceTemplate, currency(forecast.projectedSpend))
        case .risk:
            return String(format: strings.goalsForecastGoOverTemplate, currency(forecast.projectedOverLimitAmount))
        case .over:
            return String(format: strings.goalsForecastOverSummary, currency(forecast.projectedOverLimitAmount))
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
        let strings = AppStrings.current()
        switch self {
        case .all:
            return strings.historyFilterAllDates
        case .today:
            return strings.historyFilterToday
        case .week:
            return strings.historyFilterWeek
        case .month:
            return strings.historyFilterMonth
        }
    }
}
