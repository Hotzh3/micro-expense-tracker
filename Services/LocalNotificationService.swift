import Foundation
import UserNotifications

struct BudgetAlertCandidate: Equatable {
    let cadence: SpendingGoalCadence
    let periodKey: String
    let percentUsed: Double
    let remainingAmount: Double
    let thresholdAmount: Double
    let identifier: String
    let title: String
    let body: String
}

final class LocalNotificationService {
    static let shared = LocalNotificationService()

    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard

    private init() {}

    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("Local notifications authorization failed: \(error)")
            return false
        }
    }

    func syncRecurringNotifications() async {
        guard isMasterEnabled else {
            cancelAllPocketLeakNotifications()
            return
        }

        let status = await authorizationStatus()
        guard canSchedule(for: status) else {
            cancelAllPocketLeakNotifications()
            return
        }

        if dailyRemindersEnabled {
            await scheduleDailyReminders()
        } else {
            cancel(ids: LocalNotificationIdentifier.dailyReminderIDs.map(\.rawValue))
        }
    }

    func syncGoalWarnings(goalForecasts: [GoalForecast]) async {
        await syncBudgetAlerts(goalForecasts: goalForecasts)
    }

    func cancelAllPocketLeakNotifications() {
        cancel(ids: LocalNotificationIdentifier.all.map(\.rawValue))
        clearBudgetAlertHistory()
    }

    private var isMasterEnabled: Bool {
        defaults.object(forKey: AppPreferenceKeys.localNotificationsEnabled) == nil
            ? false
            : defaults.bool(forKey: AppPreferenceKeys.localNotificationsEnabled)
    }

    private var dailyRemindersEnabled: Bool {
        defaults.bool(forKey: AppPreferenceKeys.dailyCheckInEnabled)
    }

    private var budgetAlertsEnabled: Bool {
        defaults.bool(forKey: AppPreferenceKeys.goalWarningsEnabled)
    }

    private func canSchedule(for status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }

    private func scheduleDailyReminders() async {
        let reminders: [(LocalNotificationIdentifier, Int, Int, String, String)] = [
            (
                .dailyReminderAt2PM,
                14,
                0,
                localizedDailyReminderTitle(),
                localizedDailyReminderBody(at: 2)
            ),
            (
                .dailyReminderAt8PM,
                20,
                0,
                localizedDailyReminderTitle(),
                localizedDailyReminderBody(at: 8)
            )
        ]

        for reminder in reminders {
            let content = notificationContent(title: reminder.3, body: reminder.4)
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: DateComponents(hour: reminder.1, minute: reminder.2),
                repeats: true
            )
            await schedule(identifier: reminder.0.rawValue, content: content, trigger: trigger)
        }
    }

    private func syncBudgetAlerts(goalForecasts: [GoalForecast]) async {
        guard isMasterEnabled, budgetAlertsEnabled else {
            cancelBudgetAlertNotifications()
            return
        }

        let status = await authorizationStatus()
        guard canSchedule(for: status) else {
            cancelBudgetAlertNotifications()
            return
        }

        let candidates = budgetAlertCandidates(from: goalForecasts)
        guard !candidates.isEmpty else {
            cancelBudgetAlertNotifications()
            return
        }

        for candidate in candidates {
            guard shouldScheduleBudgetAlert(candidate) else { continue }
            let content = notificationContent(title: candidate.title, body: candidate.body)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            await schedule(identifier: candidate.identifier, content: content, trigger: trigger)
            storeBudgetAlertPeriodKey(candidate.periodKey, for: candidate.cadence)
        }
    }

    func budgetAlertCandidates(from goalForecasts: [GoalForecast]) -> [BudgetAlertCandidate] {
        goalForecasts.compactMap { forecast in
            guard forecast.limit.isFinite, forecast.limit > 0 else { return nil }
            guard forecast.percentUsed.isFinite, forecast.percentUsed >= 80 else { return nil }

            let periodKey = budgetAlertPeriodKey(for: forecast.goalType)
            let identifier = forecast.goalType == .weekly
                ? LocalNotificationIdentifier.weeklyBudgetAlert.rawValue
                : LocalNotificationIdentifier.monthlyBudgetAlert.rawValue
            let remainingAmount = max(forecast.remaining, 0)
            let title = localizedBudgetAlertTitle(for: forecast.goalType, percentUsed: forecast.percentUsed)
            let body = localizedBudgetAlertBody(for: forecast.goalType, percentUsed: forecast.percentUsed, remainingAmount: remainingAmount)

            return BudgetAlertCandidate(
                cadence: forecast.goalType,
                periodKey: periodKey,
                percentUsed: forecast.percentUsed,
                remainingAmount: remainingAmount,
                thresholdAmount: forecast.limit * 0.8,
                identifier: identifier,
                title: title,
                body: body
            )
        }
        .sorted { lhs, rhs in
            if lhs.cadence == rhs.cadence {
                return lhs.percentUsed > rhs.percentUsed
            }
            return lhs.cadence == .weekly && rhs.cadence == .monthly
        }
    }

    func shouldScheduleBudgetAlert(_ candidate: BudgetAlertCandidate) -> Bool {
        let storedKey = budgetAlertPeriodKeyKey(for: candidate.cadence)
        let lastKey = defaults.string(forKey: storedKey)
        return lastKey != candidate.periodKey
    }

    private func storeBudgetAlertPeriodKey(_ key: String, for cadence: SpendingGoalCadence) {
        defaults.set(key, forKey: budgetAlertPeriodKeyKey(for: cadence))
    }

    private func clearBudgetAlertHistory() {
        [SpendingGoalCadence.weekly, SpendingGoalCadence.monthly].forEach { cadence in
            defaults.removeObject(forKey: budgetAlertPeriodKeyKey(for: cadence))
        }
    }

    func budgetAlertPeriodKey(for cadence: SpendingGoalCadence) -> String {
        let calendar = Calendar.current
        let now = Date.now

        switch cadence {
        case .weekly:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            let year = components.yearForWeekOfYear ?? 0
            let week = components.weekOfYear ?? 0
            return String(format: "%04d-W%02d", year, week)
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: now)
            let year = components.year ?? 0
            let month = components.month ?? 0
            return String(format: "%04d-%02d", year, month)
        }
    }

    private func budgetAlertPeriodKeyKey(for cadence: SpendingGoalCadence) -> String {
        switch cadence {
        case .weekly:
            return "app.localNotifications.budgetAlert.lastPeriod.weekly"
        case .monthly:
            return "app.localNotifications.budgetAlert.lastPeriod.monthly"
        }
    }

    private func notificationContent(title: String, body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.threadIdentifier = "pocketleak.local"
        content.categoryIdentifier = "pocketleak.local"
        return content
    }

    private func schedule(identifier: String, content: UNNotificationContent, trigger: UNNotificationTrigger?) async {
        cancel(ids: [identifier])
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await add(request)
        } catch {
            print("Failed to schedule local notification \(identifier): \(error)")
        }
    }

    private func cancelBudgetAlertNotifications() {
        cancel(ids: [
            LocalNotificationIdentifier.weeklyBudgetAlert.rawValue,
            LocalNotificationIdentifier.monthlyBudgetAlert.rawValue
        ])
    }

    private func cancel(ids: [String]) {
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    private func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { (continuation: CheckedContinuation<UNNotificationSettings, Never>) in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func localizedDailyReminderTitle() -> String {
        switch AppLanguage.current {
        case .english:
            return "Daily Reminder"
        case .spanish:
            return "Recordatorio diario"
        }
    }

    private func localizedDailyReminderBody(at hour: Int) -> String {
        switch AppLanguage.current {
        case .english:
            return hour == 2 ? "Remember to log your expenses." : "Don't forget to capture today's spending."
        case .spanish:
            return hour == 2 ? "Recuerda registrar tus gastos." : "No olvides capturar el gasto de hoy."
        }
    }

    private func localizedBudgetAlertTitle(for cadence: SpendingGoalCadence, percentUsed: Double) -> String {
        let label = cadence == .weekly ? "Weekly" : "Monthly"
        switch AppLanguage.current {
        case .english:
            return percentUsed >= 100 ? "\(label) budget over limit" : "\(label) budget at risk"
        case .spanish:
            return percentUsed >= 100 ? "Presupuesto \(label.lowercased()) sobre el límite" : "Presupuesto \(label.lowercased()) en riesgo"
        }
    }

    private func localizedBudgetAlertBody(for cadence: SpendingGoalCadence, percentUsed: Double, remainingAmount: Double) -> String {
        let remainingText = currency(remainingAmount)
        let percentText = String(format: "%.0f%%", percentUsed)

        switch AppLanguage.current {
        case .english:
            if cadence == .weekly {
                return "You have used \(percentText) of your weekly limit. \(remainingText) remains."
            } else {
                return "You have used \(percentText) of your monthly limit. \(remainingText) remains."
            }
        case .spanish:
            if cadence == .weekly {
                return "Has usado \(percentText) de tu límite semanal. Quedan \(remainingText)."
            } else {
                return "Has usado \(percentText) de tu límite mensual. Quedan \(remainingText)."
            }
        }
    }

    private func currency(_ amount: Double) -> String {
        String(format: "$%.2f", amount)
    }
}

private enum LocalNotificationIdentifier: String, CaseIterable {
    case dailyReminderAt2PM
    case dailyReminderAt8PM
    case weeklyBudgetAlert
    case monthlyBudgetAlert

    static var dailyReminderIDs: [LocalNotificationIdentifier] {
        [.dailyReminderAt2PM, .dailyReminderAt8PM]
    }

    static var all: [LocalNotificationIdentifier] {
        dailyReminderIDs + [.weeklyBudgetAlert, .monthlyBudgetAlert]
    }
}
