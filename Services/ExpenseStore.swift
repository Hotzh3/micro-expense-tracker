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
            return try decoder.decode([Expense].self, from: data)
        } catch {
            print("Failed to load expenses: \(error)")
            return []
        }
    }

    func saveExpenses(_ expenses: [Expense]) {
        do {
            let data = try encoder.encode(expenses)
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

    private static func makeFileURL(fileManager: FileManager) -> URL {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return baseDirectory
            .appendingPathComponent("JTap", isDirectory: true)
            .appendingPathComponent("expenses.json")
    }
}
