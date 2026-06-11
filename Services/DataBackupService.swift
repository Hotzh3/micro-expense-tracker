import Foundation

enum DataBackupRestoreMode: String, CaseIterable, Identifiable, Codable {
    case merge
    case replace

    var id: String { rawValue }
}

struct DataBackupSettingsSnapshot: Codable, Equatable {
    let appearance: String
    let textSize: String
    let language: String
    let hapticsEnabled: Bool
    let smartAlertsEnabled: Bool
    let appLockEnabled: Bool?
    let requireFaceIDOnLaunch: Bool?
    let privacyModeHideAmounts: Bool?
    let hideAmountsInWidgets: Bool?
    let localNotificationsEnabled: Bool
    let dailyCheckInEnabled: Bool
    let goalWarningsEnabled: Bool
    let weeklyDigestReminderEnabled: Bool
    let dailyCheckInHour: Int
    let dailyCheckInMinute: Int
    let weeklyDigestWeekday: Int
    let weeklyDigestHour: Int
    let weeklyDigestMinute: Int
    let hasSeenOnboarding: Bool
}

struct DataBackupDocument: Codable, Equatable {
    let schemaVersion: Int
    let exportedAt: Date
    let expenses: [Expense]
    let goals: SpendingGoals
    let categoryBudgets: [CategoryBudget]
    let recurringExpenses: [RecurringExpense]
    let settings: DataBackupSettingsSnapshot?
}

struct DataBackupExport {
    let fileName: String
    let json: String
    let fileURL: URL
}

struct DataBackupRestorationSummary: Equatable {
    let expenseCount: Int
    let goalCount: Int
    let categoryBudgetCount: Int
    let recurringExpenseCount: Int
    let settingsApplied: Bool
}

final class DataBackupService {
    static let schemaVersion = 1

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func export(
        expenses: [Expense],
        goals: SpendingGoals,
        categoryBudgets: [CategoryBudget],
        recurringExpenses: [RecurringExpense],
        settings: DataBackupSettingsSnapshot,
        fileName: String? = nil
    ) -> DataBackupExport {
        let document = DataBackupDocument(
            schemaVersion: Self.schemaVersion,
            exportedAt: .now,
            expenses: expenses.filter { $0.amount.isFinite && $0.amount > 0 },
            goals: goals.sanitized,
            categoryBudgets: sanitizeBudgets(categoryBudgets),
            recurringExpenses: sanitizeRecurringExpenses(recurringExpenses),
            settings: settings
        )

        return makeExport(from: document, fileName: fileName)
    }

    func makeExport(from document: DataBackupDocument, fileName: String? = nil) -> DataBackupExport {
        let resolvedFileName = fileName ?? defaultFileName(for: document.exportedAt)
        let data = (try? encoder.encode(document)) ?? Data("{}".utf8)
        let json = String(data: data, encoding: .utf8) ?? "{}"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(resolvedFileName)
        try? data.write(to: fileURL, options: [.atomic])

        return DataBackupExport(
            fileName: resolvedFileName,
            json: json,
            fileURL: fileURL
        )
    }

    func loadBackup(from url: URL) -> DataBackupDocument? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        return loadBackup(from: data)
    }

    func loadBackup(from data: Data) -> DataBackupDocument? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
            let root = object as? [String: Any]
        else {
            return nil
        }

        guard let schemaVersion = rawInt(root["schemaVersion"]), schemaVersion == Self.schemaVersion else {
            return nil
        }

        let exportedAt = rawDate(root["exportedAt"]) ?? .now
        let expenses = decodeExpenses(from: root["expenses"])
        let goals = decodeGoals(from: root["goals"])
        let categoryBudgets = decodeCategoryBudgets(from: root["categoryBudgets"])
        let recurringExpenses = decodeRecurringExpenses(from: root["recurringExpenses"])
        let settings = decodeSettingsSnapshot(from: root["settings"])

        return DataBackupDocument(
            schemaVersion: schemaVersion,
            exportedAt: exportedAt,
            expenses: expenses,
            goals: goals,
            categoryBudgets: categoryBudgets,
            recurringExpenses: recurringExpenses,
            settings: settings
        )
    }

    private func decodeExpenses(from rawValue: Any?) -> [Expense] {
        let decoded = decodeLossyArray(from: rawValue, as: Expense.self)
        return decoded.filter { $0.amount.isFinite && $0.amount > 0 }
    }

    private func decodeGoals(from rawValue: Any?) -> SpendingGoals {
        guard let raw = rawValue as? [String: Any] else {
            return .empty
        }

        if let decoded: SpendingGoals = decodeValue(from: raw) {
            return decoded.sanitized
        }

        let weekly: SpendingGoal? = decodeValue(from: raw["weekly"])
        let monthly: SpendingGoal? = decodeValue(from: raw["monthly"])
        return SpendingGoals(weekly: weekly, monthly: monthly).sanitized
    }

    private func decodeCategoryBudgets(from rawValue: Any?) -> [CategoryBudget] {
        sanitizeBudgets(decodeLossyArray(from: rawValue, as: CategoryBudget.self))
    }

    private func decodeRecurringExpenses(from rawValue: Any?) -> [RecurringExpense] {
        sanitizeRecurringExpenses(decodeLossyArray(from: rawValue, as: RecurringExpense.self))
    }

    private func decodeSettingsSnapshot(from rawValue: Any?) -> DataBackupSettingsSnapshot? {
        guard let raw = rawValue else { return nil }
        return decodeValue(from: raw)
    }

    private func decodeLossyArray<T: Decodable>(from rawValue: Any?, as type: T.Type) -> [T] {
        guard let array = rawValue as? [Any] else {
            return []
        }

        return array.compactMap { element in
            guard JSONSerialization.isValidJSONObject(element) else {
                return nil
            }

            guard let data = try? JSONSerialization.data(withJSONObject: element) else {
                return nil
            }

            return try? decoder.decode(T.self, from: data)
        }
    }

    private func decodeValue<T: Decodable>(from rawValue: Any?) -> T? {
        guard let rawValue, JSONSerialization.isValidJSONObject(rawValue) else {
            return nil
        }

        guard let data = try? JSONSerialization.data(withJSONObject: rawValue) else {
            return nil
        }

        return try? decoder.decode(T.self, from: data)
    }

    private func sanitizeBudgets(_ budgets: [CategoryBudget]) -> [CategoryBudget] {
        var latestByKey: [String: CategoryBudget] = [:]

        for budget in budgets {
            let category = ExpenseCategory.category(
                matching: budget.category.displayName,
                in: ExpenseCategory.allDefaults
            ) ?? budget.category

            let sanitized = CategoryBudget(
                id: budget.id,
                category: category,
                cadence: budget.cadence,
                limit: budget.limit,
                createdAt: budget.createdAt,
                updatedAt: budget.updatedAt,
                isActive: budget.isActive
            )

            guard sanitized.isValid else {
                continue
            }

            if let existing = latestByKey[sanitized.storageKey] {
                if sanitized.updatedAt >= existing.updatedAt {
                    latestByKey[sanitized.storageKey] = sanitized
                }
            } else {
                latestByKey[sanitized.storageKey] = sanitized
            }
        }

        return latestByKey.values.sorted { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt {
                return lhs.category.displayName < rhs.category.displayName
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private func sanitizeRecurringExpenses(_ recurringExpenses: [RecurringExpense]) -> [RecurringExpense] {
        var latestByID: [UUID: RecurringExpense] = [:]

        for recurring in recurringExpenses {
            let category = ExpenseCategory.category(
                matching: recurring.category.displayName,
                in: ExpenseCategory.allDefaults
            ) ?? recurring.category

            let sanitized = RecurringExpense(
                id: recurring.id,
                merchant: recurring.merchant.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: recurring.amount,
                category: category,
                cadence: recurring.cadence,
                nextDueDate: recurring.nextDueDate,
                isActive: recurring.isActive,
                createdAt: recurring.createdAt,
                updatedAt: recurring.updatedAt
            )

            guard sanitized.isValid else {
                continue
            }

            if let existing = latestByID[sanitized.id] {
                if sanitized.updatedAt >= existing.updatedAt {
                    latestByID[sanitized.id] = sanitized
                }
            } else {
                latestByID[sanitized.id] = sanitized
            }
        }

        return latestByID.values.sorted { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt {
                return lhs.nextDueDate < rhs.nextDueDate
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private func rawInt(_ value: Any?) -> Int? {
        if let int = value as? Int {
            return int
        }

        if let number = value as? NSNumber {
            return number.intValue
        }

        return nil
    }

    private func rawDate(_ value: Any?) -> Date? {
        guard let string = value as? String else { return nil }

        if let date = PocketLeakFormatters.iso8601FractionalFormatter.date(from: string) {
            return date
        }

        return PocketLeakFormatters.iso8601Formatter.date(from: string)
    }

    private func defaultFileName(for date: Date) -> String {
        return "Pocket-Leak-Backup-\(PocketLeakFormatters.backupFileDateFormatter.string(from: date)).json"
    }
}
