import LocalAuthentication
import UIKit

final class AppLockService {
    static let shared = AppLockService()

    private init() {}

    func biometryDescription() -> String {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)

        switch context.biometryType {
        case .faceID:
            return "Face ID or device passcode"
        case .touchID:
            return "Touch ID or device passcode"
        case .opticID:
            return "Optic ID or device passcode"
        default:
            return "Device passcode"
        }
    }

    func authenticate(reason: String) async -> Bool {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return true
        }

        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
