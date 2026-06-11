import Foundation

struct DemoDataManifest: Codable, Equatable {
    let generatedAt: Date
    let expenseIDs: [UUID]
    let goalIDs: [UUID]
    let categoryBudgetIDs: [UUID]
    let recurringExpenseIDs: [UUID]
}

struct DemoDataState {
    let expenses: [Expense]
    let goals: SpendingGoals
    let categoryBudgets: [CategoryBudget]
    let recurringExpenses: [RecurringExpense]
    let manifest: DemoDataManifest
}

struct DemoDataGenerator {
    struct StressScenario: Equatable {
        let days: Int
        let expensesPerDay: Int

        static let thirtyDaysFivePerDay = StressScenario(days: 30, expensesPerDay: 5)
        static let sixtyDaysTenPerDay = StressScenario(days: 60, expensesPerDay: 10)
        static let ninetyDaysTwentyPerDay = StressScenario(days: 90, expensesPerDay: 20)
        static let oneEightyDaysThirtyPerDay = StressScenario(days: 180, expensesPerDay: 30)
        static let threeHundredSixtyFiveDaysTenPerDay = StressScenario(days: 365, expensesPerDay: 10)
    }

    private struct MerchantTemplate {
        let merchant: String
        let category: ExpenseCategory
        let amountRange: ClosedRange<Double>
        let noteSamples: [String]
        let weekdayWeight: Int
        let weekendWeight: Int
    }

    private struct SeededGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
        }

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }

        mutating func nextInt(upperBound: Int) -> Int {
            guard upperBound > 0 else { return 0 }
            return Int(next() % UInt64(upperBound))
        }

        mutating func nextBool() -> Bool {
            nextInt(upperBound: 2) == 0
        }

        mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
            let lower = min(range.lowerBound, range.upperBound)
            let upper = max(range.lowerBound, range.upperBound)
            guard lower.isFinite, upper.isFinite, upper > lower else {
                return lower.isFinite ? lower : 1
            }

            let fraction = Double(next()) / Double(UInt64.max)
            let value = lower + (upper - lower) * fraction
            let rounded = (value * 100).rounded() / 100
            return rounded.isFinite ? rounded : lower
        }
    }

    private let calendar: Calendar
    private let referenceDate: Date
    private let merchants: [MerchantTemplate]
    private let seed: UInt64

    init(
        referenceDate: Date = .now,
        calendar: Calendar = .current,
        seed: UInt64? = nil
    ) {
        self.referenceDate = referenceDate
        self.calendar = calendar
        self.seed = seed ?? UInt64(referenceDate.timeIntervalSinceReferenceDate.bitPattern)
        self.merchants = [
            MerchantTemplate(merchant: "Starbucks", category: .coffee, amountRange: 54...168, noteSamples: ["Morning latte", "Work session", "Coffee break"], weekdayWeight: 10, weekendWeight: 7),
            MerchantTemplate(merchant: "Café Central", category: .coffee, amountRange: 42...124, noteSamples: ["Cold brew", "Desk coffee", "Iced latte"], weekdayWeight: 8, weekendWeight: 6),
            MerchantTemplate(merchant: "OXXO", category: .convenience, amountRange: 22...189, noteSamples: ["Water and snacks", "Quick stop", "Morning essentials"], weekdayWeight: 9, weekendWeight: 10),
            MerchantTemplate(merchant: "7-Eleven", category: .convenience, amountRange: 18...149, noteSamples: ["Coffee stop", "Snack run", "Last minute pickup"], weekdayWeight: 8, weekendWeight: 9),
            MerchantTemplate(merchant: "Uber", category: .transport, amountRange: 35...220, noteSamples: ["Ride home", "Airport trip", "Late commute"], weekdayWeight: 10, weekendWeight: 6),
            MerchantTemplate(merchant: "Didi", category: .transport, amountRange: 30...180, noteSamples: ["Morning ride", "Evening trip", "Errands"], weekdayWeight: 8, weekendWeight: 5),
            MerchantTemplate(merchant: "Metro", category: .transport, amountRange: 10...45, noteSamples: ["Transit pass", "Commute", "Line transfer"], weekdayWeight: 7, weekendWeight: 3),
            MerchantTemplate(merchant: "Rappi", category: .food, amountRange: 72...580, noteSamples: ["Delivery lunch", "Grocery delivery", "Dinner delivery"], weekdayWeight: 8, weekendWeight: 8),
            MerchantTemplate(merchant: "Toks", category: .food, amountRange: 120...540, noteSamples: ["Lunch", "Dinner", "Team meal"], weekdayWeight: 9, weekendWeight: 10),
            MerchantTemplate(merchant: "Taqueria El Paraiso", category: .food, amountRange: 88...360, noteSamples: ["Tacos", "Family meal", "Quick lunch"], weekdayWeight: 7, weekendWeight: 10),
            MerchantTemplate(merchant: "Walmart", category: .shopping, amountRange: 95...1880, noteSamples: ["Groceries", "Household items", "Weekly shop"], weekdayWeight: 6, weekendWeight: 9),
            MerchantTemplate(merchant: "Amazon", category: .shopping, amountRange: 120...2480, noteSamples: ["Online order", "Household restock", "Impulse buy"], weekdayWeight: 5, weekendWeight: 8),
            MerchantTemplate(merchant: "Liverpool", category: .shopping, amountRange: 240...4200, noteSamples: ["Wardrobe refresh", "Home purchase", "Gift"], weekdayWeight: 3, weekendWeight: 6),
            MerchantTemplate(merchant: "Cinépolis", category: .entertainment, amountRange: 90...430, noteSamples: ["Movie night", "Tickets and snacks", "Weekend cinema"], weekdayWeight: 3, weekendWeight: 8),
            MerchantTemplate(merchant: "Netflix", category: .entertainment, amountRange: 129...249, noteSamples: ["Streaming renewal", "Subscription"], weekdayWeight: 2, weekendWeight: 2),
            MerchantTemplate(merchant: "Spotify", category: .entertainment, amountRange: 99...159, noteSamples: ["Music renewal", "Subscription"], weekdayWeight: 2, weekendWeight: 2),
            MerchantTemplate(merchant: "Farmacia San Pablo", category: .other, amountRange: 55...410, noteSamples: ["Medicines", "Health supplies", "Pharmacy run"], weekdayWeight: 4, weekendWeight: 2),
            MerchantTemplate(merchant: "Clínica Vida", category: .other, amountRange: 220...980, noteSamples: ["Checkup", "Consultation", "Health visit"], weekdayWeight: 2, weekendWeight: 1),
            MerchantTemplate(merchant: "GymFit", category: .other, amountRange: 389...799, noteSamples: ["Monthly membership", "Gym renewal"], weekdayWeight: 2, weekendWeight: 1)
        ]
    }

    func makeDemoState(days: Int = 45) -> DemoDataState {
        let demoExpenses = generateDemoExpenses(days: days)
        let currentWeekExpenses = expenses(in: demoExpenses, matching: .weekOfYear)
        let currentMonthExpenses = expenses(in: demoExpenses, matching: .month)
        let currentWeekTotals = categoryTotals(in: currentWeekExpenses)
        let currentMonthTotals = categoryTotals(in: currentMonthExpenses)
        let weeklyTotal = currentWeekExpenses.reduce(0) { $0 + $1.amount }
        let monthlyTotal = currentMonthExpenses.reduce(0) { $0 + $1.amount }
        let goals = makeGoals(weeklyTotal: weeklyTotal, monthlyTotal: monthlyTotal)
        let categoryBudgets = makeCategoryBudgets(
            currentWeekTotals: currentWeekTotals,
            currentMonthTotals: currentMonthTotals
        )
        let recurringExpenses = makeRecurringExpenses()

        return DemoDataState(
            expenses: demoExpenses,
            goals: goals,
            categoryBudgets: categoryBudgets,
            recurringExpenses: recurringExpenses,
            manifest: DemoDataManifest(
                generatedAt: referenceDate,
                expenseIDs: demoExpenses.map(\.id),
                goalIDs: goals.activeGoals.map(\.id),
                categoryBudgetIDs: categoryBudgets.map(\.id),
                recurringExpenseIDs: recurringExpenses.map(\.id)
            )
        )
    }

    func generateExpenses(days: Int, expensesPerDay: Int) -> [Expense] {
        let sanitizedDays = max(days, 1)
        let sanitizedPerDay = max(expensesPerDay, 1)
        var rng = SeededGenerator(seed: seed ^ UInt64(sanitizedDays &* 31 &+ sanitizedPerDay &* 17))
        var generated: [Expense] = []
        generated.reserveCapacity(sanitizedDays * sanitizedPerDay)

        for dayOffset in 0..<sanitizedDays {
            guard let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: referenceDate) else {
                continue
            }

            let dayStart = calendar.startOfDay(for: dayDate)

            for expenseIndex in 0..<sanitizedPerDay {
                let template = merchants[rng.nextInt(upperBound: merchants.count)]
                let amount = rng.nextDouble(in: template.amountRange)
                let note = (dayOffset + expenseIndex) % 3 == 0
                    ? template.noteSamples[rng.nextInt(upperBound: template.noteSamples.count)]
                    : ""
                let hour = 7 + rng.nextInt(upperBound: 13)
                let minute = rng.nextInt(upperBound: 60)
                let second = rng.nextInt(upperBound: 60)
                let date = calendar.date(bySettingHour: hour, minute: minute, second: second, of: dayStart) ?? dayStart
                let category = ExpenseCategory.category(matching: template.merchant, in: ExpenseCategory.allDefaults) ?? template.category

                generated.append(
                    Expense(
                        amount: amount,
                        category: category,
                        merchant: template.merchant,
                        note: note,
                        date: date,
                        source: .demo,
                        confidence: 1.0,
                        createdAt: date
                    )
                )
            }
        }

        return generated.sorted { lhs, rhs in
            if lhs.date == rhs.date {
                return lhs.amount > rhs.amount
            }
            return lhs.date > rhs.date
        }
    }

    private func generateDemoExpenses(days: Int) -> [Expense] {
        let sanitizedDays = max(days, 1)
        var rng = SeededGenerator(seed: seed ^ UInt64(sanitizedDays &* 97))
        var generated: [Expense] = []
        generated.reserveCapacity(sanitizedDays * 5)

        for dayOffset in 0..<sanitizedDays {
            guard let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: referenceDate) else {
                continue
            }

            let dayStart = calendar.startOfDay(for: dayDate)
            let weekday = calendar.component(.weekday, from: dayStart)
            let weekend = weekday == 1 || weekday == 7
            let dailyCountBase = weekend ? 4 : 3
            let dailyCount = dailyCountBase + rng.nextInt(upperBound: weekend ? 3 : 2)
            let recencyBoost = 0.92 + (Double(sanitizedDays - dayOffset) / Double(sanitizedDays)) * 0.25
            let weeklyWave = 1.0 + (0.14 * sin(Double(dayOffset) * .pi / 3.5))
            let weekendBoost = weekend ? 1.12 : 1.0

            for entryIndex in 0..<dailyCount {
                let template = pickTemplate(for: weekday, rng: &rng)
                let dayPartBoost: Double
                switch entryIndex {
                case 0:
                    dayPartBoost = 0.92
                case 1:
                    dayPartBoost = 1.0
                case 2:
                    dayPartBoost = 1.04
                default:
                    dayPartBoost = 1.1
                }

                let categoryBoost: Double
                switch template.category.displayName.lowercased() {
                case "coffee":
                    categoryBoost = weekend ? 0.88 : 1.06
                case "transport":
                    categoryBoost = weekend ? 0.82 : 1.02
                case "food":
                    categoryBoost = weekend ? 1.12 : 0.98
                case "entertainment":
                    categoryBoost = weekend ? 1.18 : 0.94
                case "shopping":
                    categoryBoost = weekend ? 1.16 : 0.9
                default:
                    categoryBoost = weekend ? 1.02 : 0.96
                }

                var amount = rng.nextDouble(in: template.amountRange)
                amount *= recencyBoost * weeklyWave * weekendBoost * dayPartBoost * categoryBoost
                amount = roundCurrency(amount)
                amount = max(amount, template.amountRange.lowerBound)

                let note = ((dayOffset + entryIndex) % 2 == 0)
                    ? template.noteSamples[rng.nextInt(upperBound: template.noteSamples.count)]
                    : ""
                let hour = weekend ? 9 + rng.nextInt(upperBound: 11) : 7 + rng.nextInt(upperBound: 13)
                let minute = rng.nextInt(upperBound: 60)
                let second = rng.nextInt(upperBound: 60)
                let date = calendar.date(bySettingHour: hour, minute: minute, second: second, of: dayStart) ?? dayStart

                generated.append(
                    Expense(
                        amount: amount,
                        category: template.category,
                        merchant: template.merchant,
                        note: note,
                        date: date,
                        source: .demo,
                        confidence: 1.0,
                        createdAt: date
                    )
                )
            }
        }

        return generated.sorted { lhs, rhs in
            if lhs.date == rhs.date {
                if lhs.amount == rhs.amount {
                    return lhs.merchant < rhs.merchant
                }
                return lhs.amount > rhs.amount
            }
            return lhs.date > rhs.date
        }
    }

    private func makeGoals(weeklyTotal: Double, monthlyTotal: Double) -> SpendingGoals {
        let normalizedWeekly = max(weeklyTotal, 1)
        let normalizedMonthly = max(monthlyTotal, 1)
        let weeklyGoal = SpendingGoal(
            cadence: .weekly,
            limit: roundCurrency(normalizedWeekly * 1.08),
            createdAt: referenceDate.addingTimeInterval(-10 * 86_400),
            updatedAt: referenceDate.addingTimeInterval(-2 * 86_400)
        )
        let monthlyGoal = SpendingGoal(
            cadence: .monthly,
            limit: roundCurrency(normalizedMonthly * 1.32),
            createdAt: referenceDate.addingTimeInterval(-20 * 86_400),
            updatedAt: referenceDate.addingTimeInterval(-3 * 86_400)
        )

        return SpendingGoals(weekly: weeklyGoal, monthly: monthlyGoal)
    }

    private func makeCategoryBudgets(
        currentWeekTotals: [ExpenseCategory: Double],
        currentMonthTotals: [ExpenseCategory: Double]
    ) -> [CategoryBudget] {
        let targets: [(ExpenseCategory, SpendingGoalCadence, Double)] = [
            (.coffee, .monthly, 1.35),
            (.food, .weekly, 1.08),
            (.transport, .weekly, 0.9),
            (.shopping, .monthly, 1.12),
            (.entertainment, .monthly, 0.96),
            (.convenience, .weekly, 1.16)
        ]

        return targets.compactMap { category, cadence, multiplier in
            let spent = cadence == .weekly
                ? currentWeekTotals[category] ?? 0
                : currentMonthTotals[category] ?? 0

            guard spent > 0 else { return nil }

            let safeMultiplier = max(multiplier, 0.5)
            let baseLimit = roundCurrency(max(spent * safeMultiplier, spent + 18))
            let createdAt = referenceDate.addingTimeInterval(-12 * 86_400)
            let updatedAt = referenceDate.addingTimeInterval(-1 * 86_400)

            return CategoryBudget(
                category: category,
                cadence: cadence,
                limit: baseLimit,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isActive: true
            )
        }
    }

    private func makeRecurringExpenses() -> [RecurringExpense] {
        let dueOffsets: [(String, Double, ExpenseCategory, RecurringExpenseCadence, Int)] = [
            ("Netflix", 149, .entertainment, .monthly, 4),
            ("Spotify", 99, .entertainment, .monthly, 8),
            ("GymFit", 499, .other, .monthly, 2),
            ("iCloud+", 129, .other, .monthly, 11),
            ("Phone plan", 349, .other, .monthly, 14)
        ]

        return dueOffsets.map { merchant, amount, category, cadence, dueDays in
            RecurringExpense(
                merchant: merchant,
                amount: amount,
                category: category,
                cadence: cadence,
                nextDueDate: calendar.date(byAdding: .day, value: dueDays, to: referenceDate) ?? referenceDate,
                isActive: true,
                createdAt: referenceDate.addingTimeInterval(-30 * 86_400),
                updatedAt: referenceDate.addingTimeInterval(-2 * 86_400)
            )
        }
    }

    private func pickTemplate(for weekday: Int, rng: inout SeededGenerator) -> MerchantTemplate {
        let weekend = weekday == 1 || weekday == 7
        let weightedTemplates = merchants.map { template -> (MerchantTemplate, Int) in
            let weight = weekend ? template.weekendWeight : template.weekdayWeight
            return (template, max(weight, 1))
        }

        let totalWeight = weightedTemplates.reduce(0) { $0 + $1.1 }
        guard totalWeight > 0 else {
            return merchants[rng.nextInt(upperBound: merchants.count)]
        }

        var roll = rng.nextInt(upperBound: totalWeight)
        for (template, weight) in weightedTemplates {
            if roll < weight {
                return template
            }
            roll -= weight
        }

        return merchants[rng.nextInt(upperBound: merchants.count)]
    }

    private func expenses(in expenses: [Expense], matching component: Calendar.Component) -> [Expense] {
        let interval = calendar.dateInterval(of: component, for: referenceDate)
        guard let interval else { return [] }

        return expenses.filter { expense in
            expense.date >= interval.start && expense.date < interval.end
        }
    }

    private func categoryTotals(in expenses: [Expense]) -> [ExpenseCategory: Double] {
        var totals: [ExpenseCategory: Double] = [:]
        for expense in expenses {
            totals[expense.category, default: 0] += expense.amount
        }
        return totals
    }

    private func roundCurrency(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return (value * 100).rounded() / 100
    }
}
