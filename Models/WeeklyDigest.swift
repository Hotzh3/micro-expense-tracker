import Foundation

struct WeeklyDigest: Identifiable, Equatable {
    let weekStart: Date
    let weekEnd: Date
    let totalSpend: Double
    let expenseCount: Int
    let topCategory: ExpenseCategory?
    let topMerchant: String?
    let highestSpendingDay: Date?
    let daysWithExpenses: Int
    let totalDaysInWeek: Int
    let averageDailySpend: Double
    let largestExpense: Expense?
    let bestInsight: SmartInsight?
    let goalStatus: GoalForecastStatus?
    let comparisonVsLastWeek: SpendingComparison?
    let summaryText: String
    let highlightTexts: [String]

    var id: Date { weekStart }

    init(
        weekStart: Date,
        weekEnd: Date,
        totalSpend: Double,
        expenseCount: Int,
        topCategory: ExpenseCategory?,
        topMerchant: String?,
        highestSpendingDay: Date?,
        daysWithExpenses: Int,
        totalDaysInWeek: Int,
        averageDailySpend: Double,
        largestExpense: Expense?,
        bestInsight: SmartInsight?,
        goalStatus: GoalForecastStatus?,
        comparisonVsLastWeek: SpendingComparison?,
        summaryText: String,
        highlightTexts: [String]
    ) {
        self.weekStart = weekStart
        self.weekEnd = weekEnd
        self.totalSpend = totalSpend
        self.expenseCount = expenseCount
        self.topCategory = topCategory
        self.topMerchant = topMerchant
        self.highestSpendingDay = highestSpendingDay
        self.daysWithExpenses = daysWithExpenses
        self.totalDaysInWeek = totalDaysInWeek
        self.averageDailySpend = averageDailySpend
        self.largestExpense = largestExpense
        self.bestInsight = bestInsight
        self.goalStatus = goalStatus
        self.comparisonVsLastWeek = comparisonVsLastWeek
        self.summaryText = summaryText
        self.highlightTexts = highlightTexts
    }

    var hasEnoughData: Bool {
        expenseCount > 0
    }
}
