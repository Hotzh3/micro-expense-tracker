import Foundation

final class CategoryBudgetStore {
    private let fileManager: FileManager
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.fileURL = Self.makeFileURL(fileManager: fileManager)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadBudgets() -> [CategoryBudget] {
        do {
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return []
            }

            let data = try Data(contentsOf: fileURL)
            guard let budgets = try? decoder.decode([CategoryBudget].self, from: data) else {
                print("CategoryBudgetStore decode failed; clearing corrupt budgets")
                removeCorruptBudgetsFile()
                return []
            }

            let sanitized = sanitizeBudgets(budgets)
            if sanitized.count != budgets.count {
                print("Invalid budget ignored: sanitized stored budgets")
                saveBudgets(sanitized)
            }
            return sanitized
        } catch {
            print("Failed to load category budgets: \(error)")
            print("CategoryBudgetStore decode failed; clearing corrupt budgets")
            removeCorruptBudgetsFile()
            return []
        }
    }

    func saveBudgets(_ budgets: [CategoryBudget]) {
        do {
            try ensureStoreDirectoryExists()
            let sanitizedBudgets = sanitizeBudgets(budgets)
            if sanitizedBudgets.isEmpty {
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                }
                return
            }

            let data = try encoder.encode(sanitizedBudgets)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save category budgets: \(error)")
        }
    }

    private func sanitizeBudgets(_ budgets: [CategoryBudget]) -> [CategoryBudget] {
        var latestByKey: [String: CategoryBudget] = [:]

        for budget in budgets {
            let normalizedCategory = ExpenseCategory.category(
                matching: budget.category.displayName,
                in: ExpenseCategory.allDefaults
            ) ?? budget.category

            let sanitized = CategoryBudget(
                id: budget.id,
                category: normalizedCategory,
                cadence: budget.cadence,
                limit: budget.limit,
                createdAt: budget.createdAt,
                updatedAt: budget.updatedAt,
                isActive: budget.isActive
            )

            guard sanitized.isValid else {
                print("Invalid budget ignored:", budget)
                continue
            }

            let key = sanitized.storageKey
            if let existing = latestByKey[key] {
                if sanitized.updatedAt >= existing.updatedAt {
                    latestByKey[key] = sanitized
                }
            } else {
                latestByKey[key] = sanitized
            }
        }

        return latestByKey.values.sorted { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt {
                return lhs.category.displayName < rhs.category.displayName
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private func ensureStoreDirectoryExists() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private func removeCorruptBudgetsFile() {
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to remove corrupt category budgets file: \(error)")
        }
    }

    private static func makeFileURL(fileManager: FileManager) -> URL {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return baseDirectory
            .appendingPathComponent("JTap", isDirectory: true)
            .appendingPathComponent("category-budgets.json")
    }
}
