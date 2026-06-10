import Foundation

final class GoalStore {
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

    func loadGoals() -> SpendingGoals {
        do {
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return .empty
            }

            let data = try Data(contentsOf: fileURL)
            if let goals = try? decoder.decode(SpendingGoals.self, from: data) {
                let sanitized = goals.sanitized
                if sanitized != goals {
                    saveGoals(sanitized)
                }
                return sanitized
            }

            if let legacyGoal = try? decoder.decode(SpendingGoal.self, from: data) {
                guard legacyGoal.isValid else {
                    removeCorruptGoalsFile()
                    return .empty
                }
                let goals: SpendingGoals
                switch legacyGoal.cadence {
                case .weekly:
                    goals = SpendingGoals(weekly: legacyGoal, monthly: nil)
                case .monthly:
                    goals = SpendingGoals(weekly: nil, monthly: legacyGoal)
                }
                saveGoals(goals)
                return goals
            }

            removeCorruptGoalsFile()
            return .empty
        } catch {
            print("Failed to load goals: \(error)")
            removeCorruptGoalsFile()
            return .empty
        }
    }

    func saveGoals(_ goals: SpendingGoals) {
        do {
            try ensureStoreDirectoryExists()
            let sanitizedGoals = goals.sanitized
            if sanitizedGoals.isEmpty {
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                }
                return
            }

            let data = try encoder.encode(sanitizedGoals)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save goals: \(error)")
        }
    }

    private func ensureStoreDirectoryExists() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private func removeCorruptGoalsFile() {
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to remove corrupt goals file: \(error)")
        }
    }

    private static func makeFileURL(fileManager: FileManager) -> URL {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return baseDirectory
            .appendingPathComponent("JTap", isDirectory: true)
            .appendingPathComponent("goal.json")
    }
}
