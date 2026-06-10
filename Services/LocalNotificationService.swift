import Foundation
import UserNotifications

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

        if dailyCheckInEnabled {
            await scheduleDailyCheckIn()
        } else {
            cancel(ids: [LocalNotificationIdentifier.dailyCheckIn.rawValue])
        }

        if weeklyDigestReminderEnabled {
            await scheduleWeeklyDigestReminder()
        } else {
            cancel(ids: [LocalNotificationIdentifier.weeklyDigest.rawValue])
        }
    }

    func syncGoalWarnings(goalForecasts: [GoalForecast]) async {
        guard isMasterEnabled, goalWarningsEnabled else {
            cancelGoalWarningNotifications()
            return
        }

        let status = await authorizationStatus()
        guard canSchedule(for: status) else {
            cancelGoalWarningNotifications()
            return
        }

        let warnings = goalForecasts
            .filter { $0.status != .safe }
            .sorted { lhs, rhs in
                if lhs.status.priority == rhs.status.priority {
                    return lhs.goalType == .weekly && rhs.goalType == .monthly
                }
                return lhs.status.priority > rhs.status.priority
            }

        guard !warnings.isEmpty else {
            cancelGoalWarningNotifications()
            return
        }

        for forecast in warnings {
            await scheduleGoalWarning(for: forecast)
        }
    }

    func cancelAllPocketLeakNotifications() {
        cancel(ids: LocalNotificationIdentifier.all.map(\.rawValue))
        clearGoalWarningHistory()
    }

    func cancelGoalWarningNotifications() {
        cancel(ids: [
            LocalNotificationIdentifier.weeklyGoalWarning.rawValue,
            LocalNotificationIdentifier.monthlyGoalWarning.rawValue
        ])
        clearGoalWarningHistory()
    }

    private var isMasterEnabled: Bool {
        defaults.object(forKey: AppPreferenceKeys.localNotificationsEnabled) == nil
            ? false
            : defaults.bool(forKey: AppPreferenceKeys.localNotificationsEnabled)
    }

    private var dailyCheckInEnabled: Bool {
        defaults.bool(forKey: AppPreferenceKeys.dailyCheckInEnabled)
    }

    private var goalWarningsEnabled: Bool {
        defaults.bool(forKey: AppPreferenceKeys.goalWarningsEnabled)
    }

    private var weeklyDigestReminderEnabled: Bool {
        defaults.bool(forKey: AppPreferenceKeys.weeklyDigestReminderEnabled)
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

    private func scheduleDailyCheckIn() async {
        let hour = clampedInt(for: AppPreferenceKeys.dailyCheckInHour, lower: 0, upper: 23, fallback: 18)
        let minute = clampedInt(for: AppPreferenceKeys.dailyCheckInMinute, lower: 0, upper: 59, fallback: 0)
        let content = notificationContent(
            title: localizedDailyCheckInTitle(),
            body: localizedDailyCheckInBody()
        )
        let components = DateComponents(hour: hour, minute: minute)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        await schedule(identifier: LocalNotificationIdentifier.dailyCheckIn.rawValue, content: content, trigger: trigger)
    }

    private func scheduleWeeklyDigestReminder() async {
        let weekday = clampedInt(for: AppPreferenceKeys.weeklyDigestWeekday, lower: 1, upper: 7, fallback: 1)
        let hour = clampedInt(for: AppPreferenceKeys.weeklyDigestHour, lower: 0, upper: 23, fallback: 9)
        let minute = clampedInt(for: AppPreferenceKeys.weeklyDigestMinute, lower: 0, upper: 59, fallback: 0)
        let content = notificationContent(
            title: localizedWeeklyDigestTitle(),
            body: localizedWeeklyDigestBody()
        )
        let components = DateComponents(hour: hour, minute: minute, weekday: weekday)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        await schedule(identifier: LocalNotificationIdentifier.weeklyDigest.rawValue, content: content, trigger: trigger)
    }

    private func scheduleGoalWarning(for forecast: GoalForecast) async {
        let identifier = forecast.goalType == .weekly
            ? LocalNotificationIdentifier.weeklyGoalWarning.rawValue
            : LocalNotificationIdentifier.monthlyGoalWarning.rawValue
        let fingerprint = goalWarningFingerprint(for: forecast)
        guard shouldScheduleGoalWarning(identifier: identifier, fingerprint: fingerprint) else { return }

        let content = notificationContent(
            title: localizedGoalWarningTitle(for: forecast),
            body: localizedGoalWarningBody(for: forecast)
        )
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        await schedule(identifier: identifier, content: content, trigger: trigger)
        storeGoalWarningFingerprint(fingerprint, for: identifier)
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

    private func clampedInt(for key: String, lower: Int, upper: Int, fallback: Int) -> Int {
        guard defaults.object(forKey: key) != nil else {
            return fallback
        }
        return Swift.min(Swift.max(defaults.integer(forKey: key), lower), upper)
    }

    private func localizedDailyCheckInTitle() -> String {
        switch AppLanguage.current {
        case .english:
            return "Daily Check-in"
        case .spanish:
            return "Revisión diaria"
        }
    }

    private func localizedDailyCheckInBody() -> String {
        switch AppLanguage.current {
        case .english:
            return "Add today's leaks before they disappear."
        case .spanish:
            return "Agrega las fugas de hoy antes de que se pierdan."
        }
    }

    private func localizedWeeklyDigestTitle() -> String {
        switch AppLanguage.current {
        case .english:
            return "Weekly Digest"
        case .spanish:
            return "Resumen semanal"
        }
    }

    private func localizedWeeklyDigestBody() -> String {
        switch AppLanguage.current {
        case .english:
            return "Review your weekly summary in Pocket Leak."
        case .spanish:
            return "Revisa tu resumen semanal en Pocket Leak."
        }
    }

    private func localizedGoalWarningTitle(for forecast: GoalForecast) -> String {
        switch AppLanguage.current {
        case .english:
            switch forecast.goalType {
            case .weekly:
                return forecast.status == .over ? "Weekly goal over limit" : "Weekly goal close to limit"
            case .monthly:
                return forecast.status == .over ? "Monthly goal over limit" : "Monthly goal close to limit"
            }
        case .spanish:
            switch forecast.goalType {
            case .weekly:
                return forecast.status == .over ? "Meta semanal sobre el límite" : "Meta semanal cerca del límite"
            case .monthly:
                return forecast.status == .over ? "Meta mensual sobre el límite" : "Meta mensual cerca del límite"
            }
        }
    }

    private func localizedGoalWarningBody(for forecast: GoalForecast) -> String {
        let amount = currency(forecast.status == .over ? forecast.projectedOverLimitAmount : forecast.remainingDailyBudget)
        switch AppLanguage.current {
        case .english:
            switch forecast.status {
            case .watch:
                return "You have \(amount) per day left."
            case .risk:
                return "You're projected to go over by \(currency(forecast.projectedOverLimitAmount))."
            case .over:
                return "You're already over by \(currency(forecast.projectedOverLimitAmount))."
            case .safe:
                return ""
            }
        case .spanish:
            switch forecast.status {
            case .watch:
                return "Te quedan \(amount) por día."
            case .risk:
                return "Se proyecta que te pases por \(currency(forecast.projectedOverLimitAmount))."
            case .over:
                return "Ya estás por encima por \(currency(forecast.projectedOverLimitAmount))."
            case .safe:
                return ""
            }
        }
    }

    private func goalWarningFingerprint(for forecast: GoalForecast) -> String {
        [
            forecast.goalType.rawValue,
            forecast.status.rawValue,
            String(format: "%.2f", forecast.projectedOverLimitAmount),
            String(format: "%.2f", forecast.remainingDailyBudget)
        ].joined(separator: "|")
    }

    private func shouldScheduleGoalWarning(identifier: String, fingerprint: String) -> Bool {
        let fingerprintKey = goalWarningFingerprintKey(for: identifier)
        let timestampKey = goalWarningTimestampKey(for: identifier)
        let existingFingerprint = defaults.string(forKey: fingerprintKey)
        let existingTimestamp = defaults.double(forKey: timestampKey)
        let now = Date().timeIntervalSince1970

        if existingFingerprint == fingerprint, now - existingTimestamp < 86_400 {
            return false
        }

        return true
    }

    private func storeGoalWarningFingerprint(_ fingerprint: String, for identifier: String) {
        defaults.set(fingerprint, forKey: goalWarningFingerprintKey(for: identifier))
        defaults.set(Date().timeIntervalSince1970, forKey: goalWarningTimestampKey(for: identifier))
    }

    private func clearGoalWarningHistory() {
        [LocalNotificationIdentifier.weeklyGoalWarning, LocalNotificationIdentifier.monthlyGoalWarning].forEach { identifier in
            defaults.removeObject(forKey: goalWarningFingerprintKey(for: identifier.rawValue))
            defaults.removeObject(forKey: goalWarningTimestampKey(for: identifier.rawValue))
        }
    }

    private func goalWarningFingerprintKey(for identifier: String) -> String {
        "app.localNotifications.goalWarning.fingerprint.\(identifier)"
    }

    private func goalWarningTimestampKey(for identifier: String) -> String {
        "app.localNotifications.goalWarning.timestamp.\(identifier)"
    }

    private func currency(_ amount: Double) -> String {
        String(format: "$%.2f", amount)
    }
}

private enum LocalNotificationIdentifier: String, CaseIterable {
    case dailyCheckIn
    case weeklyDigest
    case weeklyGoalWarning
    case monthlyGoalWarning

    static var all: [LocalNotificationIdentifier] {
        [.dailyCheckIn, .weeklyDigest, .weeklyGoalWarning, .monthlyGoalWarning]
    }
}
