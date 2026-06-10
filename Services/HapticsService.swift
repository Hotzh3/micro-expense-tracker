import Foundation
import UIKit

@MainActor
final class HapticsService {
    static let shared = HapticsService()

    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let softImpactGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {}

    func lightTap() {
        guard isEnabled else { return }
        lightImpactGenerator.impactOccurred(intensity: 0.7)
        lightImpactGenerator.prepare()
    }

    func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    func softImpact() {
        guard isEnabled else { return }
        softImpactGenerator.impactOccurred(intensity: 0.75)
        softImpactGenerator.prepare()
    }

    func success() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    func warning() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    func error() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    private var isEnabled: Bool {
        guard UserDefaults.standard.object(forKey: AppPreferenceKeys.hapticsEnabled) != nil else {
            return true
        }
        return UserDefaults.standard.bool(forKey: AppPreferenceKeys.hapticsEnabled)
    }
}
