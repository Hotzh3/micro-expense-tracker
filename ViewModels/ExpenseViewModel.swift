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

    struct DashboardSummary: Equatable {
        let todayTotal: Double
        let weekTotal: Double
        let monthTotal: Double
        let totalExpenseCount: Int
        let averageExpenseAmount: Double
        let highestExpense: Expense?
        let largestExpenseThisMonth: Expense?
        let topCategory: ExpenseCategory?
        let mostFrequentCategory: ExpenseCategory?
        let categorySummaries: [DashboardCategorySummary]
        let trendPoints: [DashboardTrendPoint]
        let recentExpenses: [Expense]
    }

    struct HistorySummary: Equatable {
        let filteredExpenses: [Expense]
        let filteredTotal: Double
        let filteredCount: Int
        let availableMerchants: [String]
        let availableCategories: [ExpenseCategory]
    }

    struct CalendarCategoryBreakdown: Identifiable, Equatable {
        let category: ExpenseCategory
        let total: Double
        let count: Int

        var id: UUID { category.id }
    }

    struct CalendarDayReview: Identifiable, Equatable {
        let date: Date
        let isCurrentMonth: Bool
        let total: Double
        let expenses: [Expense]
        let categoryBreakdown: [CalendarCategoryBreakdown]
        let topMerchant: String?
        let highestExpense: Expense?
        let averageComparisonText: String
        let insightText: String

        var id: Date { date }
    }

    struct CalendarMonthReview: Equatable {
        let monthStart: Date
        let monthEnd: Date
        let days: [CalendarDayReview]
        let totalSpend: Double
        let daysWithExpenses: Int
        let highestDay: CalendarDayReview?
        let averageDailySpend: Double
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

    @Published var expenses: [Expense] {
        didSet {
            rebuildExpenseAnalyticsCache()
        }
    }
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
    @Published var quickAddRouteToken: UUID = UUID()
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
    private var expenseAnalytics = ExpenseAnalyticsSnapshot.empty

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
        self.selectedCategory = initialCategory
        self.weeklyDigest = WeeklyDigest(
            weekStart: .now,
            weekEnd: .now,
            totalSpend: 0,
            expenseCount: 0,
            topCategory: nil,
            topMerchant: nil,
            highestSpendingDay: nil,
            daysWithExpenses: 0,
            totalDaysInWeek: 7,
            averageDailySpend: 0,
            largestExpense: nil,
            bestInsight: nil,
            goalStatus: nil,
            comparisonVsLastWeek: nil,
            summaryText: "",
            highlightTexts: []
        )
        self.expenses = store.loadExpenses()
        let goals = goalStore.loadGoals()
        self.weeklyGoal = goals.weekly
        self.monthlyGoal = goals.monthly
        self.categoryBudgets = categoryBudgetStore.loadBudgets()
        self.recurringExpenses = recurringExpenseStore.loadRecurringExpenses()
        self.privacyModeHideAmounts = UserDefaults.standard.bool(forKey: AppPreferenceKeys.privacyModeHideAmounts)
        self.hideAmountsInWidgets = UserDefaults.standard.bool(forKey: AppPreferenceKeys.hideAmountsInWidgets)
        rebuildExpenseAnalyticsCache()
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

    func saveDraftExpense(date: Date = .now) {
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
            date: date,
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

    func prefillFromParsedText(_ text: String) {
        let sanitized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { return }

        guard let suggestion = parser.parse(sanitized, categories: categories) else {
            return
        }

        guard let amount = suggestion.amount, amount.isFinite, amount > 0 else {
            return
        }

        amountText = amountText(for: amount)
        merchantText = suggestion.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        selectedCategory = resolvedCategory(from: suggestion.category)
        noteText = ""
        importText = sanitized
        parsedExpense = nil
        parseFeedback = nil
        draftSource = .parsedText
        draftConfidence = safeConfidence(suggestion.confidence)
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
        clearDemoDataManifest()
        smartAlertService.clearDismissedAlerts()
        refreshSmartAlerts()
        syncLocalNotifications()
    }

    func loadDemoData(days: Int = 45) {
        let generator = DemoDataGenerator(referenceDate: .now)
        let demoState = generator.makeDemoState(days: days)

        expenses = demoState.expenses
        weeklyGoal = demoState.goals.weekly
        monthlyGoal = demoState.goals.monthly
        categoryBudgets = demoState.categoryBudgets
        recurringExpenses = demoState.recurringExpenses
        persistExpenses(refreshDerivedState: false)
        persistGoals(refreshDerivedState: false)
        persistCategoryBudgets()
        persistRecurringExpenses()
        saveDemoDataManifest(demoState.manifest)
        smartAlertService.clearDismissedAlerts()
        refreshDerivedDataAfterMutation()
    }

    @discardableResult
    func resetDemoData() -> Bool {
        guard let manifest = loadDemoDataManifest() else {
            return false
        }

        let demoExpenseIDs = Set(manifest.expenseIDs)
        expenses.removeAll { $0.source == .demo || demoExpenseIDs.contains($0.id) }

        if let weeklyGoal, manifest.goalIDs.contains(weeklyGoal.id) {
            self.weeklyGoal = nil
        }

        if let monthlyGoal, manifest.goalIDs.contains(monthlyGoal.id) {
            self.monthlyGoal = nil
        }

        categoryBudgets.removeAll { manifest.categoryBudgetIDs.contains($0.id) }
        recurringExpenses.removeAll { manifest.recurringExpenseIDs.contains($0.id) }
        clearDemoDataManifest()
        persistExpenses(refreshDerivedState: false)
        persistGoals(refreshDerivedState: false)
        persistCategoryBudgets()
        persistRecurringExpenses()
        refreshDerivedDataAfterMutation()
        return true
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
        clearDemoDataManifest()

        return DataBackupRestorationSummary(
            expenseCount: importedExpenses.count,
            goalCount: importedGoals.activeGoals.count,
            categoryBudgetCount: importedBudgets.count,
            recurringExpenseCount: importedRecurringExpenses.count,
            settingsApplied: backup.settings != nil
        )
    }

#if DEBUG
    func loadStressDemoData(days: Int, expensesPerDay: Int) {
        let generator = DemoDataGenerator()
        let generatedExpenses = generator.generateExpenses(days: days, expensesPerDay: expensesPerDay)

        print("Generating stress demo data:", days, expensesPerDay, generatedExpenses.count)
        expenses = generatedExpenses
        persistExpenses()

        showSaveFeedback(
            message: "Generated \(generatedExpenses.count) stress demo expenses",
            isError: false
        )
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
        refreshWeeklyDigest()
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
        refreshWeeklyDigest()
    }

    func removeRecurringExpense(id: UUID) {
        print("Removing recurring expense:", id)
        recurringExpenses.removeAll { $0.id == id }
        persistRecurringExpenses()
        refreshWeeklyDigest()
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
        let matchingExpenses = expenseAnalytics.safeExpenses.filter { filter.matches($0, calendar: calendar) }
        return filter.sortOrder.sorted(matchingExpenses)
    }

    func filteredExpenseCount(using filter: ExpenseFilter) -> Int {
        historySummary(using: filter).filteredCount
    }

    func filteredExpenseTotal(using filter: ExpenseFilter) -> Double {
        historySummary(using: filter).filteredTotal
    }

    var availableMerchants: [String] {
        expenseAnalytics.availableMerchants
    }

    var todayTotal: Double {
        expenseAnalytics.todayTotal
    }

    var weekTotal: Double {
        expenseAnalytics.weekTotal
    }

    var monthTotal: Double {
        expenseAnalytics.monthTotal
    }

    var totalExpenseCount: Int {
        expenseAnalytics.totalExpenseCount
    }

    var expenseCountThisMonth: Int {
        expenseAnalytics.expenseCountThisMonth
    }

    var averageExpenseAmount: Double {
        expenseAnalytics.averageExpenseAmount
    }

    var averageDailySpend: Double {
        expenseAnalytics.averageDailySpend
    }

    var projectedMonthlySpend: Double {
        expenseAnalytics.projectedMonthSpend
    }

    var projectedMonthSpend: Double {
        expenseAnalytics.projectedMonthSpend
    }

    var daysLeftInMonth: Int {
        expenseAnalytics.daysLeftInMonth
    }

    var daysLeftInWeek: Int {
        expenseAnalytics.daysLeftInWeek
    }

    var highestExpense: Expense? {
        expenseAnalytics.highestExpense
    }

    var largestExpenseThisMonth: Expense? {
        expenseAnalytics.largestExpenseThisMonth
    }

    var topCategory: ExpenseCategory? {
        expenseAnalytics.topCategory
    }

    var mostFrequentCategory: ExpenseCategory? {
        expenseAnalytics.mostFrequentCategory
    }

    var categoryBreakdown: [CategoryBreakdown] {
        expenseAnalytics.monthCategoryBreakdownByAmount
    }

    var categorySpendChartData: [CategorySpendPoint] {
        expenseAnalytics.monthCategoryBreakdownByAmount.map {
            CategorySpendPoint(category: $0.category, total: $0.total)
        }
    }

    var topCategorySharesThisMonth: [CategoryShare] {
        Array(categorySharesThisMonth.prefix(3))
    }

    var categorySharesThisMonth: [CategoryShare] {
        expenseAnalytics.categorySharesThisMonth
    }

    var dashboardCategorySummariesSafe: [DashboardCategorySummary] {
        expenseAnalytics.dashboardCategorySummaries
    }

    var dashboardTrendPointsSafe: [DashboardTrendPoint] {
        expenseAnalytics.dashboardTrendPoints
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
        let monthExpenses = expenseAnalytics.monthExpenses
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

        let thisWeekTotal = weekTotal
        let previousWeekTotal = expenseAnalytics.previousWeekTotal

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
        expenseAnalytics.recentSpendTrendData
    }

    var weeklySpendTrendData: [WeeklySpendPoint] {
        expenseAnalytics.weeklySpendTrendData
    }

    var hasWeeklyTrendData: Bool {
        expenseAnalytics.hasWeeklyTrendData
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
        let points = expenseAnalytics.recentSpendTrendData
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
        let points = expenseAnalytics.weeklySpendTrendData
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

    var calendarMonthReview: CalendarMonthReview {
        calendarMonthReview(for: .now)
    }

    func calendarMonthReview(for date: Date) -> CalendarMonthReview {
        let monthInterval = calendar.dateInterval(of: .month, for: date)
        let monthStart = monthInterval?.start ?? calendar.startOfDay(for: date)
        let monthEnd = monthInterval.map { calendar.date(byAdding: .second, value: -1, to: $0.end) ?? $0.end } ?? date
        let monthExpenses = expenseAnalytics.safeExpenses.filter { expense in
            monthInterval?.contains(expense.date) == true
        }
        let dayStart = calendar.startOfDay(for: monthStart)
        let dayCount = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        let totalSpend = monthExpenses.reduce(0) { $0 + $1.amount }
        let daysWithExpenses = Set(monthExpenses.map { calendar.startOfDay(for: $0.date) }).count
        let averageDailySpend = dayCount > 0 ? totalSpend / Double(dayCount) : 0

        let days: [CalendarDayReview] = (0..<dayCount).compactMap { offset in
            guard let currentDate = calendar.date(byAdding: .day, value: offset, to: dayStart) else {
                return nil
            }
            return calendarDayReview(for: currentDate, within: monthInterval, averageDailySpend: averageDailySpend)
        }

        let highestDay = days.max { lhs, rhs in
            lhs.total < rhs.total
        }

        return CalendarMonthReview(
            monthStart: monthStart,
            monthEnd: monthEnd,
            days: days,
            totalSpend: totalSpend,
            daysWithExpenses: daysWithExpenses,
            highestDay: highestDay,
            averageDailySpend: averageDailySpend
        )
    }

    func calendarDayReview(for date: Date) -> CalendarDayReview {
        let monthInterval = calendar.dateInterval(of: .month, for: date)
        let monthReview = calendarMonthReview(for: date)
        let normalizedDate = calendar.startOfDay(for: date)

        return monthReview.days.first(where: { calendar.isDate($0.date, inSameDayAs: normalizedDate) })
            ?? calendarDayReview(for: normalizedDate, within: monthInterval, averageDailySpend: monthReview.averageDailySpend)
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

    func dashboardSummary(recentLimit: Int = 5) -> DashboardSummary {
        DashboardSummary(
            todayTotal: todayTotal,
            weekTotal: weekTotal,
            monthTotal: monthTotal,
            totalExpenseCount: totalExpenseCount,
            averageExpenseAmount: averageExpenseAmount,
            highestExpense: highestExpense,
            largestExpenseThisMonth: largestExpenseThisMonth,
            topCategory: topCategory,
            mostFrequentCategory: mostFrequentCategory,
            categorySummaries: dashboardCategorySummariesSafe,
            trendPoints: dashboardTrendPointsSafe,
            recentExpenses: Array(expenseAnalytics.recentExpenses.prefix(max(recentLimit, 0)))
        )
    }

    func historySummary(using filter: ExpenseFilter) -> HistorySummary {
        let filtered = filteredExpenses(using: filter)
        let total = filtered.reduce(0) { $0 + $1.amount }
        return HistorySummary(
            filteredExpenses: filtered,
            filteredTotal: total,
            filteredCount: filtered.count,
            availableMerchants: expenseAnalytics.availableMerchants,
            availableCategories: expenseAnalytics.availableCategories
        )
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
        expenseAnalytics.safeExpenses
    }

    private var totalAmount: Double {
        expenseAnalytics.totalAmount
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
        switch range {
        case .today:
            return expenseAnalytics.todayExpenses
        case .week:
            return expenseAnalytics.weekExpenses
        case .month:
            return expenseAnalytics.monthExpenses
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
        switch sortMode {
        case .amount:
            return expenseAnalytics.monthCategoryBreakdownByAmount
        case .count:
            return expenseAnalytics.monthCategoryBreakdownByCount
        }
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
            return expenseAnalytics.weekExpenses.sorted { $0.date > $1.date }
        case .monthly:
            return expenseAnalytics.monthExpenses.sorted { $0.date > $1.date }
        case .allData:
            return expenseAnalytics.recentExpenses
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
        let total: Double
        switch range {
        case .today:
            total = expenseAnalytics.todayTotal
        case .week:
            total = expenseAnalytics.weekTotal
        case .month:
            total = expenseAnalytics.monthTotal
        }
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
        if sanitizedExpenses != expenses {
            expenses = sanitizedExpenses
        }
        store.saveExpenses(sanitizedExpenses)
        guard refreshDerivedState else { return }
        refreshDerivedDataAfterMutation()
    }

    private func persistGoals(refreshDerivedState: Bool = true) {
        let sanitizedGoals = SpendingGoals(weekly: weeklyGoal, monthly: monthlyGoal).sanitized
        goalStore.saveGoals(sanitizedGoals)
        weeklyGoal = sanitizedGoals.weekly
        monthlyGoal = sanitizedGoals.monthly

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
        categoryBudgets = sanitizedBudgets
    }

    private func persistRecurringExpenses() {
        let sanitizedRecurring = recurringExpenses.filter { $0.isValid }
        if sanitizedRecurring.count != recurringExpenses.count {
            recurringExpenses = sanitizedRecurring
        }
        recurringExpenseStore.saveRecurringExpenses(sanitizedRecurring)
        recurringExpenses = sanitizedRecurring
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

    private func saveDemoDataManifest(_ manifest: DemoDataManifest) {
        do {
            let data = try JSONEncoder().encode(manifest)
            UserDefaults.standard.set(data, forKey: AppPreferenceKeys.demoDataManifest)
        } catch {
            print("Failed to save demo data manifest: \(error)")
        }
    }

    private func loadDemoDataManifest() -> DemoDataManifest? {
        guard let data = UserDefaults.standard.data(forKey: AppPreferenceKeys.demoDataManifest) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(DemoDataManifest.self, from: data)
        } catch {
            print("Failed to decode demo data manifest: \(error)")
            clearDemoDataManifest()
            return nil
        }
    }

    private func clearDemoDataManifest() {
        UserDefaults.standard.removeObject(forKey: AppPreferenceKeys.demoDataManifest)
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

    private func calendarDayReview(
        for date: Date,
        within monthInterval: DateInterval?,
        averageDailySpend: Double
    ) -> CalendarDayReview {
        let normalizedDate = calendar.startOfDay(for: date)
        let dayExpenses = expenseAnalytics.safeExpenses.filter { expense in
            calendar.isDate(expense.date, inSameDayAs: normalizedDate)
        }

        let total = dayExpenses.reduce(0) { $0 + $1.amount }
        let breakdown = categoryBreakdown(from: dayExpenses, sortMode: .amount).map {
            CalendarCategoryBreakdown(category: $0.category, total: $0.total, count: $0.count)
        }
        let merchantTotals = Dictionary(grouping: dayExpenses) { expense -> String in
            let merchant = expense.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
            return merchant.isEmpty ? expense.category.displayName : merchant
        }
        .mapValues { items in
            items.reduce(0) { $0 + $1.amount }
        }

        let topMerchant = merchantTotals.sorted { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key.localizedCaseInsensitiveCompare(rhs.key) == .orderedAscending
            }
            return lhs.value > rhs.value
        }.first?.key

        let highestExpense = dayExpenses.max(by: { $0.amount < $1.amount })
        let comparisonValue = averageDailySpend > 0 ? total / averageDailySpend : 0
        let averageComparisonText: String
        switch AppLanguage.current {
        case .english:
            if averageDailySpend <= 0 {
                averageComparisonText = "No monthly average yet."
            } else if comparisonValue > 1.05 {
                averageComparisonText = String(format: "This day was %@ above your daily average.", percentageString((comparisonValue - 1) * 100))
            } else if comparisonValue < 0.95 {
                averageComparisonText = String(format: "This day was %@ below your daily average.", percentageString((1 - comparisonValue) * 100))
            } else {
                averageComparisonText = "This day matched your daily average."
            }
        case .spanish:
            if averageDailySpend <= 0 {
                averageComparisonText = "Aún no hay promedio mensual."
            } else if comparisonValue > 1.05 {
                averageComparisonText = String(format: "Este día estuvo %@ por encima de tu promedio diario.", percentageString((comparisonValue - 1) * 100))
            } else if comparisonValue < 0.95 {
                averageComparisonText = String(format: "Este día estuvo %@ por debajo de tu promedio diario.", percentageString((1 - comparisonValue) * 100))
            } else {
                averageComparisonText = "Este día estuvo cerca de tu promedio diario."
            }
        }

        let insightText: String
        switch AppLanguage.current {
        case .english:
            if dayExpenses.isEmpty {
                insightText = "No expenses recorded for this day."
            } else if let highestExpense {
                let merchant = highestExpense.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
                let label = merchant.isEmpty ? highestExpense.category.displayName : merchant
                insightText = "Top spend was \(currency(highestExpense.amount)) at \(label)."
            } else {
                insightText = "Expenses were recorded for this day."
            }
        case .spanish:
            if dayExpenses.isEmpty {
                insightText = "No hay gastos registrados en este día."
            } else if let highestExpense {
                let merchant = highestExpense.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
                let label = merchant.isEmpty ? highestExpense.category.displayName : merchant
                insightText = "El gasto más alto fue \(currency(highestExpense.amount)) en \(label)."
            } else {
                insightText = "Hay gastos registrados para este día."
            }
        }

        return CalendarDayReview(
            date: normalizedDate,
            isCurrentMonth: monthInterval?.contains(normalizedDate) == true,
            total: total,
            expenses: dayExpenses.sorted { $0.date > $1.date },
            categoryBreakdown: breakdown,
            topMerchant: topMerchant,
            highestExpense: highestExpense,
            averageComparisonText: averageComparisonText,
            insightText: insightText
        )
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
            recurringExpenses: recurringExpenses,
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

    private func rebuildExpenseAnalyticsCache() {
        expenseAnalytics = ExpenseAnalyticsSnapshot.make(from: expenses, calendar: calendar)
    }
}

private struct ExpenseAnalyticsSnapshot {
    let safeExpenses: [Expense]
    let todayExpenses: [Expense]
    let weekExpenses: [Expense]
    let monthExpenses: [Expense]
    let recentExpenses: [Expense]
    let availableMerchants: [String]
    let availableCategories: [ExpenseCategory]
    let totalAmount: Double
    let todayTotal: Double
    let weekTotal: Double
    let monthTotal: Double
    let totalExpenseCount: Int
    let expenseCountThisMonth: Int
    let averageExpenseAmount: Double
    let averageDailySpend: Double
    let projectedMonthSpend: Double
    let daysLeftInWeek: Int
    let daysLeftInMonth: Int
    let highestExpense: Expense?
    let largestExpenseThisMonth: Expense?
    let topCategory: ExpenseCategory?
    let mostFrequentCategory: ExpenseCategory?
    let monthCategoryBreakdownByAmount: [ExpenseViewModel.CategoryBreakdown]
    let monthCategoryBreakdownByCount: [ExpenseViewModel.CategoryBreakdown]
    let categorySharesThisMonth: [ExpenseViewModel.CategoryShare]
    let dashboardCategorySummaries: [ExpenseViewModel.DashboardCategorySummary]
    let dashboardTrendPoints: [ExpenseViewModel.DashboardTrendPoint]
    let recentSpendTrendData: [ExpenseViewModel.DailySpendPoint]
    let weeklySpendTrendData: [ExpenseViewModel.WeeklySpendPoint]
    let hasWeeklyTrendData: Bool
    let currentWeekTotal: Double
    let previousWeekTotal: Double

    static let empty = ExpenseAnalyticsSnapshot(
        safeExpenses: [],
        todayExpenses: [],
        weekExpenses: [],
        monthExpenses: [],
        recentExpenses: [],
        availableMerchants: [],
        availableCategories: [],
        totalAmount: 0,
        todayTotal: 0,
        weekTotal: 0,
        monthTotal: 0,
        totalExpenseCount: 0,
        expenseCountThisMonth: 0,
        averageExpenseAmount: 0,
        averageDailySpend: 0,
        projectedMonthSpend: 0,
        daysLeftInWeek: 1,
        daysLeftInMonth: 1,
        highestExpense: nil,
        largestExpenseThisMonth: nil,
        topCategory: nil,
        mostFrequentCategory: nil,
        monthCategoryBreakdownByAmount: [],
        monthCategoryBreakdownByCount: [],
        categorySharesThisMonth: [],
        dashboardCategorySummaries: [],
        dashboardTrendPoints: [],
        recentSpendTrendData: [],
        weeklySpendTrendData: [],
        hasWeeklyTrendData: false,
        currentWeekTotal: 0,
        previousWeekTotal: 0
    )

    static func make(from expenses: [Expense], calendar: Calendar) -> ExpenseAnalyticsSnapshot {
        let safeExpenses = expenses.filter { $0.amount.isFinite }
        let validExpenses = safeExpenses.filter { $0.amount > 0 }
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: .now)
        let monthInterval = calendar.dateInterval(of: .month, for: .now)

        let todayExpenses = validExpenses.filter { calendar.isDateInToday($0.date) }
        let weekExpenses = validExpenses.filter { expense in
            weekInterval?.contains(expense.date) == true
        }
        let monthExpenses = validExpenses.filter { expense in
            monthInterval?.contains(expense.date) == true
        }

        let recentExpenses = validExpenses.sorted { $0.date > $1.date }
        let availableMerchants = Array(
            Set(
                validExpenses
                    .map { $0.merchant.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted { lhs, rhs in
            lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }

        let availableCategories = Array(Set(validExpenses.map(\.category)))
            .sorted { lhs, rhs in
                lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }

        func sum(_ items: [Expense]) -> Double {
            items.reduce(0) { $0 + $1.amount }
        }

        func breakdown(from items: [Expense], sortByCount: Bool) -> [ExpenseViewModel.CategoryBreakdown] {
            let grouped = Dictionary(grouping: items, by: { $0.category.id })

            let breakdown = grouped.compactMap { categoryID, groupedItems -> ExpenseViewModel.CategoryBreakdown? in
                guard let category = groupedItems.first?.category ?? items.first(where: { $0.category.id == categoryID })?.category else {
                    return nil
                }

                let total = sum(groupedItems)
                guard total.isFinite, total > 0 else { return nil }

                return ExpenseViewModel.CategoryBreakdown(
                    category: category,
                    total: total,
                    count: groupedItems.count
                )
            }

            if sortByCount {
                return breakdown.sorted {
                    if $0.count == $1.count {
                        return $0.total > $1.total
                    }
                    return $0.count > $1.count
                }
            }

            return breakdown.sorted { lhs, rhs in
                if lhs.total == rhs.total {
                    return lhs.category.displayName < rhs.category.displayName
                }
                return lhs.total > rhs.total
            }
        }

        let totalAmount = sum(validExpenses)
        let todayTotal = sum(todayExpenses)
        let weekTotal = sum(weekExpenses)
        let monthTotal = sum(monthExpenses)
        let totalExpenseCount = validExpenses.count
        let expenseCountThisMonth = monthExpenses.count
        let averageExpenseAmount = totalExpenseCount > 0 ? totalAmount / Double(totalExpenseCount) : 0
        let elapsedDays = max(calendar.component(.day, from: .now), 1)
        let averageDailySpend = monthTotal > 0 ? monthTotal / Double(elapsedDays) : 0
        let daysInCurrentMonth = calendar.range(of: .day, in: .month, for: .now)?.count ?? 30
        let projectedMonthSpend = averageDailySpend * Double(daysInCurrentMonth)

        func daysLeft(in range: ExpenseViewModel.TimeRange) -> Int {
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

        let highestExpense = validExpenses.max(by: { $0.amount < $1.amount })
        let largestExpenseThisMonth = monthExpenses.max(by: { $0.amount < $1.amount })
        let monthBreakdownByAmount = breakdown(from: monthExpenses, sortByCount: false)
        let monthBreakdownByCount = breakdown(from: monthExpenses, sortByCount: true)

        let monthShares: [ExpenseViewModel.CategoryShare]
        if monthTotal > 0 {
            monthShares = monthBreakdownByAmount.map { item in
                ExpenseViewModel.CategoryShare(
                    category: item.category,
                    total: item.total,
                    count: item.count,
                    percentage: (item.total / monthTotal) * 100
                )
            }
        } else {
            monthShares = []
        }

        let dashboardCategorySummaries: [ExpenseViewModel.DashboardCategorySummary] = {
            let grouped = Dictionary(grouping: monthExpenses, by: { expense -> String in
                expense.category.slug.isEmpty ? expense.category.displayName.lowercased() : expense.category.slug
            })

            return grouped.compactMap { key, items in
                guard let category = items.first?.category else { return nil }
                let total = sum(items)
                guard total.isFinite, total > 0 else { return nil }
                let percentage = monthTotal > 0 ? min(max(total / monthTotal, 0), 1) : 0
                return ExpenseViewModel.DashboardCategorySummary(
                    key: key,
                    categoryName: category.displayName,
                    total: total,
                    count: items.count,
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
        }()

        let daysToShow = 14
        let startDate = calendar.date(byAdding: .day, value: -(daysToShow - 1), to: calendar.startOfDay(for: .now))
        let dashboardTrendPoints: [ExpenseViewModel.DashboardTrendPoint] = {
            guard let startDate else { return [] }

            let totalsByDay = Dictionary(
                grouping: validExpenses,
                by: { calendar.startOfDay(for: $0.date) }
            ).mapValues { sum($0) }

            return (0..<daysToShow).compactMap { index in
                guard let date = calendar.date(byAdding: .day, value: index, to: startDate) else {
                    return nil
                }

                let total = totalsByDay[date] ?? 0
                guard total.isFinite, total >= 0 else { return nil }
                return ExpenseViewModel.DashboardTrendPoint(index: index, date: date, total: total)
            }
        }()

        let recentSpendTrendData: [ExpenseViewModel.DailySpendPoint] = {
            guard let startDate else { return [] }
            let totalsByDay = Dictionary(
                grouping: validExpenses,
                by: { calendar.startOfDay(for: $0.date) }
            ).mapValues { sum($0) }

            return (0..<daysToShow).compactMap { offset in
                guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else {
                    return nil
                }

                return ExpenseViewModel.DailySpendPoint(
                    date: date,
                    total: totalsByDay[date] ?? 0
                )
            }
        }()

        let weeksToShow = 6
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start
        let weeklySpendTrendData: [ExpenseViewModel.WeeklySpendPoint] = {
            guard let currentWeekStart else { return [] }

            let totalsByWeek = Dictionary(
                grouping: validExpenses,
                by: { expense in
                    calendar.dateInterval(of: .weekOfYear, for: expense.date)?.start ?? calendar.startOfDay(for: expense.date)
                }
            ).mapValues { sum($0) }

            return (0..<weeksToShow).compactMap { offset in
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: offset - (weeksToShow - 1), to: currentWeekStart) else {
                    return nil
                }

                return ExpenseViewModel.WeeklySpendPoint(
                    weekStart: weekStart,
                    total: totalsByWeek[weekStart] ?? 0
                )
            }
        }()

        let hasWeeklyTrendData = Set(
            validExpenses.compactMap { expense in
                calendar.dateInterval(of: .weekOfYear, for: expense.date)?.start
            }
        ).count >= 2

        let previousWeekStart = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: .now)) ?? .now
        let previousWeekEnd = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: .now)) ?? .now
        let previousWeekTotal = validExpenses.filter { expense in
            expense.date >= previousWeekStart && expense.date <= previousWeekEnd
        }.reduce(0) { $0 + $1.amount }

        return ExpenseAnalyticsSnapshot(
            safeExpenses: safeExpenses,
            todayExpenses: todayExpenses,
            weekExpenses: weekExpenses,
            monthExpenses: monthExpenses,
            recentExpenses: recentExpenses,
            availableMerchants: availableMerchants,
            availableCategories: availableCategories,
            totalAmount: totalAmount,
            todayTotal: todayTotal,
            weekTotal: weekTotal,
            monthTotal: monthTotal,
            totalExpenseCount: totalExpenseCount,
            expenseCountThisMonth: expenseCountThisMonth,
            averageExpenseAmount: averageExpenseAmount,
            averageDailySpend: averageDailySpend,
            projectedMonthSpend: projectedMonthSpend,
            daysLeftInWeek: daysLeft(in: .week),
            daysLeftInMonth: daysLeft(in: .month),
            highestExpense: highestExpense,
            largestExpenseThisMonth: largestExpenseThisMonth,
            topCategory: monthBreakdownByAmount.first?.category,
            mostFrequentCategory: monthBreakdownByCount.first?.category,
            monthCategoryBreakdownByAmount: monthBreakdownByAmount,
            monthCategoryBreakdownByCount: monthBreakdownByCount,
            categorySharesThisMonth: monthShares,
            dashboardCategorySummaries: dashboardCategorySummaries,
            dashboardTrendPoints: dashboardTrendPoints,
            recentSpendTrendData: recentSpendTrendData,
            weeklySpendTrendData: weeklySpendTrendData,
            hasWeeklyTrendData: hasWeeklyTrendData,
            currentWeekTotal: weekTotal,
            previousWeekTotal: previousWeekTotal
        )
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
