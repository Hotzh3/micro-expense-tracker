import Foundation

final class RecurringExpenseStore {
    private let fileManager: FileManager
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.makeFileURL(fileManager: fileManager)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadRecurringExpenses() -> [RecurringExpense] {
        do {
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return []
            }

            let data = try Data(contentsOf: fileURL)
            guard let recurring = try? decoder.decode([RecurringExpense].self, from: data) else {
                print("RecurringExpenseStore decode failed; clearing corrupt recurring expenses")
                removeCorruptRecurringExpensesFile()
                return []
            }

            let sanitized = sanitize(recurring)
            if sanitized.count != recurring.count {
                print("Invalid recurring expense ignored: sanitized stored recurring expenses")
                saveRecurringExpenses(sanitized)
            }
            return sanitized
        } catch {
            print("Failed to load recurring expenses: \(error)")
            print("RecurringExpenseStore decode failed; clearing corrupt recurring expenses")
            removeCorruptRecurringExpensesFile()
            return []
        }
    }

    func saveRecurringExpenses(_ recurringExpenses: [RecurringExpense]) {
        do {
            try ensureStoreDirectoryExists()
            let sanitized = sanitize(recurringExpenses)
            if sanitized.isEmpty {
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                }
                return
            }

            let data = try encoder.encode(sanitized)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save recurring expenses: \(error)")
        }
    }

    private func sanitize(_ recurringExpenses: [RecurringExpense]) -> [RecurringExpense] {
        recurringExpenses.compactMap { recurring in
            let category = ExpenseCategory.category(matching: recurring.category.displayName, in: ExpenseCategory.allDefaults)
                ?? recurring.category

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
                print("Invalid recurring expense ignored:", recurring)
                return nil
            }

            return sanitized
        }
    }

    private func ensureStoreDirectoryExists() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private func removeCorruptRecurringExpensesFile() {
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to remove corrupt recurring expenses file: \(error)")
        }
    }

    private static func makeFileURL(fileManager: FileManager) -> URL {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return baseDirectory
            .appendingPathComponent("JTap", isDirectory: true)
            .appendingPathComponent("recurring-expenses.json")
    }
}
