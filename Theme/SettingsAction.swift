import SwiftUI

private struct PresentSettingsActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct PresentRecurringExpensesActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var presentSettings: () -> Void {
        get { self[PresentSettingsActionKey.self] }
        set { self[PresentSettingsActionKey.self] = newValue }
    }

    var presentRecurringExpenses: () -> Void {
        get { self[PresentRecurringExpensesActionKey.self] }
        set { self[PresentRecurringExpensesActionKey.self] = newValue }
    }
}
