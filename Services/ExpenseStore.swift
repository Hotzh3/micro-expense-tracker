import Foundation

final class ExpenseStore {
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

    func loadExpenses() -> [Expense] {
        do {
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return []
            }

            let data = try Data(contentsOf: fileURL)
            let expenses = try decoder.decode([Expense].self, from: data)
            let sanitized = expenses.filter { $0.amount.isFinite && $0.amount > 0 }
            if sanitized.count != expenses.count {
                saveExpenses(sanitized)
            }
            return sanitized
        } catch {
            print("Failed to load expenses: \(error)")
            print("ExpenseStore decode failed; clearing corrupt expenses")
            removeCorruptExpensesFile()
            return []
        }
    }

    func saveExpenses(_ expenses: [Expense]) {
        do {
            let safeExpenses = expenses.filter { $0.amount.isFinite }
            let data = try encoder.encode(safeExpenses)
            try ensureStoreDirectoryExists()
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save expenses: \(error)")
        }
    }

    func sampleExpenses() -> [Expense] {
        #if DEBUG
        return [
            Expense(amount: 42, category: .coffee, merchant: "Sample Cafe", note: "Demo expense", date: .now.addingTimeInterval(-86_400), source: .demo),
            Expense(amount: 128, category: .food, merchant: "Sample Lunch Spot", note: "Demo expense", date: .now.addingTimeInterval(-172_800), source: .demo)
        ]
        #else
        return []
        #endif
    }

    private func ensureStoreDirectoryExists() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private func removeCorruptExpensesFile() {
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to remove corrupt expenses file: \(error)")
        }
    }

    private static func makeFileURL(fileManager: FileManager) -> URL {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return baseDirectory
            .appendingPathComponent("JTap", isDirectory: true)
            .appendingPathComponent("expenses.json")
    }
}
