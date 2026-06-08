import SwiftUI

private struct PresentSettingsActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var presentSettings: () -> Void {
        get { self[PresentSettingsActionKey.self] }
        set { self[PresentSettingsActionKey.self] = newValue }
    }
}
