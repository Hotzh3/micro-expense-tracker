import Foundation

final class SharedTextStore {
    static let shared = SharedTextStore()

    private static let appGroupIdentifier = "group.com.josema.PocketLeak"
    private let defaults: UserDefaults?
    private let pendingTextKey = "com.josema.pocketleak.pendingSharedText"
    private let pendingDateKey = "com.josema.pocketleak.pendingSharedTextDate"

    private init(defaults: UserDefaults? = UserDefaults(suiteName: SharedTextStore.appGroupIdentifier)) {
        self.defaults = defaults
    }

    func savePendingText(_ text: String) {
        let sanitized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { return }

        defaults?.set(sanitized, forKey: pendingTextKey)
        defaults?.set(Date(), forKey: pendingDateKey)
        defaults?.synchronize()
    }

    func consumePendingText() -> String? {
        guard let text = defaults?.string(forKey: pendingTextKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            clearPendingText()
            return nil
        }

        clearPendingText()
        return text
    }

    func clearPendingText() {
        defaults?.removeObject(forKey: pendingTextKey)
        defaults?.removeObject(forKey: pendingDateKey)
        defaults?.synchronize()
    }
}
