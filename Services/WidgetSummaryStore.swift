import Foundation

final class WidgetSummaryStore {
    static let appGroupIdentifier = "group.com.josema.PocketLeak"

    private let fileManager: FileManager
    private let fileURL: URL?
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

    var isAvailable: Bool {
        fileURL != nil
    }

    func loadSummary() -> WidgetSummary? {
        guard let fileURL else { return nil }

        do {
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return nil
            }

            let data = try Data(contentsOf: fileURL)
            let summary = try decoder.decode(WidgetSummary.self, from: data)
            guard summary.isValid else {
                print("Invalid widget summary ignored")
                clearSummary()
                return nil
            }
            return summary
        } catch {
            print("Failed to load widget summary: \(error)")
            clearSummary()
            return nil
        }
    }

    func saveSummary(_ summary: WidgetSummary) {
        guard let fileURL else { return }

        do {
            try ensureStoreDirectoryExists(at: fileURL)
            let data = try encoder.encode(summary)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save widget summary: \(error)")
        }
    }

    func clearSummary() {
        guard let fileURL else { return }

        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to clear widget summary: \(error)")
        }
    }

    private func ensureStoreDirectoryExists(at fileURL: URL) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private static func makeFileURL(fileManager: FileManager) -> URL? {
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            return nil
        }

        return containerURL
            .appendingPathComponent("PocketLeakShared", isDirectory: true)
            .appendingPathComponent("widget-summary.json")
    }
}

private extension WidgetSummary {
    var isValid: Bool {
        guard date.timeIntervalSince1970.isFinite else { return false }
        guard todayTotal.isFinite, weekTotal.isFinite, monthTotal.isFinite else { return false }
        guard categoryTop3.allSatisfy({ $0.amount.isFinite }) else { return false }
        return true
    }
}
