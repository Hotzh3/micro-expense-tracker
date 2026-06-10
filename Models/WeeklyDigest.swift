import Foundation

struct WeeklyDigest: Identifiable, Equatable {
    let weekStart: Date
    let weekEnd: Date
    let totalSpend: Double
    let expenseCount: Int
    let topCategory: ExpenseCategory?
    let averageDailySpend: Double
    let largestExpense: Expense?
    let bestInsight: SmartInsight?
    let goalStatus: GoalForecastStatus?
    let comparisonVsLastWeek: SpendingComparison?

    var id: Date { weekStart }

    init(
        weekStart: Date,
        weekEnd: Date,
        totalSpend: Double,
        expenseCount: Int,
        topCategory: ExpenseCategory?,
        averageDailySpend: Double,
        largestExpense: Expense?,
        bestInsight: SmartInsight?,
        goalStatus: GoalForecastStatus?,
        comparisonVsLastWeek: SpendingComparison?
    ) {
        self.weekStart = weekStart
        self.weekEnd = weekEnd
        self.totalSpend = totalSpend
        self.expenseCount = expenseCount
        self.topCategory = topCategory
        self.averageDailySpend = averageDailySpend
        self.largestExpense = largestExpense
        self.bestInsight = bestInsight
        self.goalStatus = goalStatus
        self.comparisonVsLastWeek = comparisonVsLastWeek
    }

    var hasEnoughData: Bool {
        expenseCount > 0
    }
}
