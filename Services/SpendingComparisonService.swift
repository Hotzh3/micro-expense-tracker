import Foundation

struct SpendingComparisonService {
    func generateComparisons(
        expenses: [Expense],
        calendar: Calendar = .current,
        strings: AppStrings = .current()
    ) -> [SpendingComparison] {
        let safeExpenses = expenses.filter { $0.amount.isFinite }
        guard !safeExpenses.isEmpty else { return [] }

        let today = Date.now
        let todayTotal = total(in: calendar.dateInterval(of: .day, for: today), expenses: safeExpenses)
        let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let yesterdayTotal = total(in: calendar.dateInterval(of: .day, for: yesterdayDate), expenses: safeExpenses)

        let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: today)
        let previousWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: today) ?? today
        let previousWeekInterval = calendar.dateInterval(of: .weekOfYear, for: previousWeekDate)
        let currentWeekExpenses = expensesForInterval(currentWeekInterval, source: safeExpenses)
        let previousWeekExpenses = expensesForInterval(previousWeekInterval, source: safeExpenses)
        let currentWeekTotal = currentWeekExpenses.reduce(0) { $0 + $1.amount }
        let previousWeekTotal = previousWeekExpenses.reduce(0) { $0 + $1.amount }

        let currentMonthInterval = calendar.dateInterval(of: .month, for: today)
        let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: today) ?? today
        let previousMonthInterval = calendar.dateInterval(of: .month, for: previousMonthDate)
        let currentMonthTotal = total(in: currentMonthInterval, expenses: safeExpenses)
        let previousMonthTotal = total(in: previousMonthInterval, expenses: safeExpenses)

        var comparisons: [SpendingComparison] = []

        if let comparison = comparison(
            title: strings.trendTodayVsYesterdayTitle,
            currentAmount: todayTotal,
            previousAmount: yesterdayTotal,
            period: .todayVsYesterday
        ) {
            comparisons.append(comparison)
        }

        if let comparison = comparison(
            title: strings.trendWeekVsLastWeekTitle,
            currentAmount: currentWeekTotal,
            previousAmount: previousWeekTotal,
            period: .weekVsLastWeek
        ) {
            comparisons.append(comparison)
        }

        if let comparison = comparison(
            title: strings.trendMonthVsLastMonthTitle,
            currentAmount: currentMonthTotal,
            previousAmount: previousMonthTotal,
            period: .monthVsLastMonth
        ) {
            comparisons.append(comparison)
        }

        let currentWeekDays = max(elapsedDays(in: currentWeekInterval, calendar: calendar), 1)
        let previousWeekDays = max(daysInPreviousWeek(previousWeekInterval, calendar: calendar), 1)
        let currentWeekAverage = currentWeekTotal.isFinite ? currentWeekTotal / Double(currentWeekDays) : 0
        let previousWeekAverage = previousWeekTotal.isFinite ? previousWeekTotal / Double(previousWeekDays) : 0
        if let comparison = comparison(
            title: strings.trendDailyAverageWeekTitle,
            currentAmount: currentWeekAverage,
            previousAmount: previousWeekAverage,
            period: .weeklyAverageVsLastWeek
        ) {
            comparisons.append(comparison)
        }

        if let topCategoryComparison = topCategoryComparison(
            currentWeekExpenses: currentWeekExpenses,
            previousWeekExpenses: previousWeekExpenses,
            strings: strings
        ) {
            comparisons.append(topCategoryComparison)
        }

        return comparisons.sorted { sortPriority(lhs: $0, rhs: $1) }
    }

    private func comparison(
        title: String,
        currentAmount: Double,
        previousAmount: Double,
        period: SpendingComparisonPeriod
    ) -> SpendingComparison? {
        guard currentAmount.isFinite, previousAmount.isFinite else { return nil }
        let deltaAmount = currentAmount - previousAmount
        guard deltaAmount.isFinite else { return nil }
        let shouldShow = currentAmount > 0 || previousAmount > 0
        guard shouldShow else { return nil }

        let direction: SpendingComparisonDirection
        let percentChange: Double

        if previousAmount <= 0 {
            direction = currentAmount > 0 ? .up : .flat
            percentChange = 0
        } else if abs(deltaAmount) < 0.01 {
            direction = .flat
            percentChange = 0
        } else if deltaAmount > 0 {
            direction = .up
            percentChange = (deltaAmount / previousAmount) * 100
        } else {
            direction = .down
            percentChange = (abs(deltaAmount) / previousAmount) * 100
        }

        return SpendingComparison(
            title: title,
            currentAmount: currentAmount,
            previousAmount: previousAmount,
            deltaAmount: deltaAmount,
            percentChange: percentChange,
            direction: direction,
            period: period
        )
    }

    private func topCategoryComparison(
        currentWeekExpenses: [Expense],
        previousWeekExpenses: [Expense],
        strings: AppStrings
    ) -> SpendingComparison? {
        guard !currentWeekExpenses.isEmpty || !previousWeekExpenses.isEmpty else { return nil }

        let currentTop = topCategory(from: currentWeekExpenses)
        let previousTop = topCategory(from: previousWeekExpenses)

        guard let currentTop, let previousTop else { return nil }

        let title = String(
            format: strings.trendTopCategoryComparisonTitleTemplate,
            currentTop.category.displayName,
            previousTop.category.displayName
        )

        return comparison(
            title: title,
            currentAmount: currentTop.total,
            previousAmount: previousTop.total,
            period: .topCategoryThisWeekVsLastWeek
        )
    }

    private func topCategory(from expenses: [Expense]) -> (category: ExpenseCategory, total: Double)? {
        let safeExpenses = expenses.filter { $0.amount.isFinite }
        let grouped = Dictionary(grouping: safeExpenses, by: { $0.category.id })
        let breakdown = grouped.compactMap { _, items -> (category: ExpenseCategory, total: Double)? in
            guard let category = items.first?.category else { return nil }
            return (category: category, total: items.reduce(0) { $0 + $1.amount })
        }
        return breakdown.sorted { $0.total > $1.total }.first
    }

    private func expensesForInterval(_ interval: DateInterval?, source expenses: [Expense]) -> [Expense] {
        guard let interval else { return [] }
        return expenses.filter { $0.amount.isFinite && interval.contains($0.date) }
    }

    private func total(in interval: DateInterval?, expenses: [Expense]) -> Double {
        expensesForInterval(interval, source: expenses).reduce(0) { $0 + $1.amount }
    }

    private func elapsedDays(in interval: DateInterval?, calendar: Calendar) -> Int {
        guard let interval else { return 1 }
        let start = calendar.startOfDay(for: interval.start)
        let now = calendar.startOfDay(for: .now)
        let difference = calendar.dateComponents([.day], from: start, to: now).day ?? 0
        return max(difference + 1, 1)
    }

    private func daysInPreviousWeek(_ interval: DateInterval?, calendar: Calendar) -> Int {
        guard let interval else { return 7 }
        let start = calendar.startOfDay(for: interval.start)
        let end = calendar.startOfDay(for: interval.end)
        let difference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(difference, 7)
    }

    private func sortPriority(lhs: SpendingComparison, rhs: SpendingComparison) -> Bool {
        priority(for: lhs.period) > priority(for: rhs.period)
    }

    private func priority(for period: SpendingComparisonPeriod) -> Int {
        switch period {
        case .weekVsLastWeek:
            return 100
        case .monthVsLastMonth:
            return 90
        case .todayVsYesterday:
            return 80
        case .weeklyAverageVsLastWeek:
            return 70
        case .topCategoryThisWeekVsLastWeek:
            return 60
        }
    }
}
