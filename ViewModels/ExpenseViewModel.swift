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
    @Published var goalForecasts: [GoalForecast] = []
    @Published var spendingComparisons: [SpendingComparison] = []
    @Published var smartInsights: [SmartInsight] = []
    @Published var smartAlerts: [SmartAlert] = []
    @Published var weeklyDigest: WeeklyDigest
    @Published var isQuickAddInputFocused: Bool = false
    @Published var isGoalsInputFocused: Bool = false

    let categories: [ExpenseCategory]

    private let store: ExpenseStore
    private let goalStore: GoalStore
    private let parser: ExpenseTextParser
    private let goalIntelligenceService: GoalIntelligenceService
    private let spendingComparisonService: SpendingComparisonService
    private let smartInsightsService: SmartInsightsService
    private let smartAlertService: SmartAlertService
    private let weeklyDigestService: WeeklyDigestService
    private let widgetSummaryStore: WidgetSummaryStore
    private let calendar: Calendar
    private let defaultCategory: ExpenseCategory
    private var draftSource: ExpenseSource = .manual
    private var draftConfidence: Double = 1.0
    private var isResettingDraft = false
    private var smartAlertsDefaultsObserver: NSObjectProtocol?

    init(
        store: ExpenseStore = ExpenseStore(),
        goalStore: GoalStore = GoalStore(),
        parser: ExpenseTextParser = ExpenseTextParser()
    ) {
        self.store = store
        self.goalStore = goalStore
        self.parser = parser
        self.goalIntelligenceService = GoalIntelligenceService()
        self.spendingComparisonService = SpendingComparisonService()
        self.smartInsightsService = SmartInsightsService()
        self.smartAlertService = SmartAlertService()
        self.weeklyDigestService = WeeklyDigestService()
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
        refreshGoalForecasts()
        refreshSpendingComparisons()
        refreshSmartInsights()
        refreshSmartAlerts()
        refreshWeeklyDigest()
        syncWidgetSummary()

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
        smartAlertService.clearDismissedAlerts()
        refreshSmartAlerts()
    }

    func clearAllGoals() {
        weeklyGoal = nil
        monthlyGoal = nil
        persistGoals()
    }

    func dismissSmartAlert(id: String) {
        smartAlertService.dismissAlert(id: id)
        refreshSmartAlerts()
    }

    func saveGoal(cadence: SpendingGoalCadence, limit: Double) {
        guard limit.isFinite, limit > 0 else { return }
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
        categoryBreakdown(in: .month, sortMode: sortMode)
    }

    private func categoryBreakdown(in range: TimeRange, sortMode: CategorySortMode) -> [CategoryBreakdown] {
        let sourceExpenses = expenses(in: range)
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

    private func persistExpenses() {
        let sanitizedExpenses = safeExpenses
        if sanitizedExpenses.count != expenses.count {
            expenses = sanitizedExpenses
        }
        store.saveExpenses(sanitizedExpenses)
        expenses = store.loadExpenses().filter { $0.amount.isFinite }
        refreshGoalForecasts()
        refreshSpendingComparisons()
        refreshSmartInsights()
        refreshSmartAlerts()
        refreshWeeklyDigest()
        syncWidgetSummary()
    }

    private func persistGoals() {
        let sanitizedGoals = SpendingGoals(weekly: weeklyGoal, monthly: monthlyGoal).sanitized
        goalStore.saveGoals(sanitizedGoals)
        let savedGoals = goalStore.loadGoals().sanitized
        weeklyGoal = savedGoals.weekly
        monthlyGoal = savedGoals.monthly
        refreshGoalForecasts()
        refreshSmartInsights()
        refreshSmartAlerts()
        refreshWeeklyDigest()
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
            weeklyGoalForecastText: widgetGoalForecastText(for: .weekly),
            monthlyGoalForecastText: widgetGoalForecastText(for: .monthly),
            categoryTop3: categoryBreakdown.prefix(3).map { WidgetCategorySummary(name: $0.category.displayName, amount: $0.total) }
        )

        widgetSummaryStore.saveSummary(summary)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
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
