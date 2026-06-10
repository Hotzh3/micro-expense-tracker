import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.appTextSize) private var appTextSize: AppTextSize
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppPreferenceKeys.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(AppPreferenceKeys.smartAlertsEnabled) private var smartAlertsEnabled = true
    @AppStorage(AppPreferenceKeys.localNotificationsEnabled) private var localNotificationsEnabled = false
    @AppStorage(AppPreferenceKeys.dailyCheckInEnabled) private var dailyCheckInEnabled = false
    @AppStorage(AppPreferenceKeys.goalWarningsEnabled) private var goalWarningsEnabled = false
    @AppStorage(AppPreferenceKeys.weeklyDigestReminderEnabled) private var weeklyDigestReminderEnabled = false
    @AppStorage(AppPreferenceKeys.dailyCheckInHour) private var dailyCheckInHour = 18
    @AppStorage(AppPreferenceKeys.dailyCheckInMinute) private var dailyCheckInMinute = 0
    @AppStorage(AppPreferenceKeys.weeklyDigestWeekday) private var weeklyDigestWeekday = 1
    @AppStorage(AppPreferenceKeys.weeklyDigestHour) private var weeklyDigestHour = 9
    @AppStorage(AppPreferenceKeys.weeklyDigestMinute) private var weeklyDigestMinute = 0

    @Binding var appearanceSelection: AppAppearance
    @Binding var textSizeSelection: AppTextSize
    @Binding var languageSelection: AppLanguage

    let versionText: String
    let onOpenHistory: (() -> Void)?
    let onOpenGoals: (() -> Void)?
    let onOpenQuickAdd: (() -> Void)?
    let onCopyQuickAddURL: (() -> Void)?
    let onCopyPrefillURLExample: (() -> Void)?
    let onOpenQuickAddRoute: (() -> Void)?
    let onSyncNotifications: (() -> Void)?
    let onShowOnboardingAgain: (() -> Void)?
    let onResetLocalData: () -> Void

    @State private var showResetConfirmation = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var notificationFeedback: String?
    @State private var isSyncingNotificationSettings = false

    private var scale: CGFloat {
        appTextSize.scale
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    headerCard

                    appearanceCard
                    textSizeCard
                    languageCard
                    onboardingCard
                    hapticsCard
                    smartAlertsCard
                    notificationsCard
                    privacyCard
                    exportCard
                    backTapCard
                    resetCard
                    versionCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(strings.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.done) {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.primaryText)
                }
            }
            .confirmationDialog(
                strings.resetConfirmationTitle,
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button(strings.deleteAllData, role: .destructive) {
                    onResetLocalData()
                }
                Button(strings.cancel, role: .cancel) {}
            } message: {
                Text(strings.resetConfirmationMessage)
            }
            .task {
                await refreshNotificationStatus()
            }
            .onChange(of: scenePhase) { _, newValue in
                guard newValue == .active else { return }
                Task { await refreshNotificationStatus() }
            }
        }
    }

    private var headerCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text(strings.appName)
                    .font(.system(size: 20 * appTextSize.scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Text(strings.settingsDescription)
                    .font(.system(size: 15 * appTextSize.scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var appearanceCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.appearanceTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Picker(strings.appearanceTitle, selection: $appearanceSelection) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
                .pickerStyle(.segmented)
                Text(strings.appearanceDescription)
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var textSizeCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.textSizeTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Picker(strings.textSizeTitle, selection: $textSizeSelection) {
                    ForEach(AppTextSize.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                Text(strings.textSizeDescription)
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var languageCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.languageTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Picker(strings.languageTitle, selection: $languageSelection) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                Text(strings.languageDescription)
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var onboardingCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.onboardingTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                Text(strings.onboardingDescription)
                    .font(.system(size: 15 * scale))
                    .foregroundStyle(AppTheme.secondaryText)

                Button {
                    dismiss()
                    DispatchQueue.main.async {
                        onShowOnboardingAgain?()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle")
                        Text(strings.showOnboardingAgain)
                    }
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.background)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.primaryText)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.showOnboardingAgain)
                .accessibilityHint(strings.onboardingDescription)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var hapticsCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.hapticsTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                Toggle(isOn: $hapticsEnabled) {
                    Text(strings.enableHaptics)
                        .font(.system(size: 15 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }
                .tint(AppTheme.primaryText)
                .accessibilityLabel(strings.enableHaptics)
                .accessibilityHint(strings.hapticsDescription)

                Text(strings.hapticsDescription)
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var smartAlertsCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.smartAlertsTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                Toggle(isOn: $smartAlertsEnabled) {
                    Text(strings.enableSmartAlerts)
                        .font(.system(size: 15 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }
                .tint(AppTheme.primaryText)
                .accessibilityLabel(strings.enableSmartAlerts)
                .accessibilityHint(strings.smartAlertsDescription)

                Text(strings.smartAlertsDescription)
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var notificationsCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.notificationsTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                Text(strings.notificationsDescription)
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(AppTheme.secondaryText)

                Toggle(isOn: $localNotificationsEnabled) {
                    Text(strings.enableLocalNotifications)
                        .font(.system(size: 15 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }
                .tint(AppTheme.primaryText)
                .onChange(of: localNotificationsEnabled) { _, _ in
                    Task { await handleNotificationSettingsChanged() }
                }

                notificationStatusRow

                if let notificationFeedback {
                    notificationFeedbackBanner(message: notificationFeedback)
                }

                Divider()
                    .overlay(AppTheme.cardBorder.opacity(0.5))

                Toggle(isOn: $dailyCheckInEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(strings.dailyCheckInTitle)
                            .font(.system(size: 15 * scale, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryText)
                        Text(strings.dailyCheckInDescription)
                            .font(.system(size: 13 * scale))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                .tint(AppTheme.primaryText)
                .disabled(!localNotificationsEnabled)
                .onChange(of: dailyCheckInEnabled) { _, _ in
                    Task { await handleNotificationSettingsChanged() }
                }

                HStack {
                    Text(strings.dailyCheckInTimeTitle)
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.tertiaryText)
                    Spacer()
                    DatePicker(
                        "",
                        selection: dailyCheckInTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .disabled(!localNotificationsEnabled || !dailyCheckInEnabled)
                }

                Toggle(isOn: $goalWarningsEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(strings.goalWarningsTitle)
                            .font(.system(size: 15 * scale, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryText)
                        Text(strings.goalWarningsDescription)
                            .font(.system(size: 13 * scale))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                .tint(AppTheme.primaryText)
                .disabled(!localNotificationsEnabled)
                .onChange(of: goalWarningsEnabled) { _, _ in
                    Task { await handleNotificationSettingsChanged() }
                }

                Toggle(isOn: $weeklyDigestReminderEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(strings.weeklyDigestReminderTitle)
                            .font(.system(size: 15 * scale, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryText)
                        Text(strings.weeklyDigestReminderDescription)
                            .font(.system(size: 13 * scale))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                .tint(AppTheme.primaryText)
                .disabled(!localNotificationsEnabled)
                .onChange(of: weeklyDigestReminderEnabled) { _, _ in
                    Task { await handleNotificationSettingsChanged() }
                }

                HStack {
                    Text(strings.weeklyDigestDayTitle)
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.tertiaryText)
                    Spacer()
                    Picker("", selection: $weeklyDigestWeekday) {
                        ForEach(1...7, id: \.self) { weekday in
                            Text(weekdayTitle(for: weekday)).tag(weekday)
                        }
                    }
                    .labelsHidden()
                    .disabled(!localNotificationsEnabled || !weeklyDigestReminderEnabled)
                    .frame(maxWidth: 170)
                }

                HStack {
                    Text(strings.weeklyDigestTimeTitle)
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.tertiaryText)
                    Spacer()
                    DatePicker(
                        "",
                        selection: weeklyDigestTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .disabled(!localNotificationsEnabled || !weeklyDigestReminderEnabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var privacyCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text(strings.privacyTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Text(strings.privacyNote)
                    .font(.system(size: 15 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var exportCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.dataTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Text(strings.exportDescription)
                    .font(.system(size: 15 * scale))
                    .foregroundStyle(AppTheme.secondaryText)

                Button {
                    dismiss()
                    onOpenHistory?()
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle")
                        Text(strings.openHistoryExports)
                    }
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.background)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.primaryText)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.openHistoryExports)
                .accessibilityHint(strings.exportDescription)

                Button {
                    dismiss()
                    onOpenGoals?()
                } label: {
                    HStack {
                        Image(systemName: "target")
                        Text(strings.openGoals)
                    }
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.cardFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.cardBorder, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.openGoals)
                .accessibilityHint(strings.goalsHeaderSubtitle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var backTapCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.backTapTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Text(strings.backTapDescription)
                    .font(.system(size: 15 * scale))
                    .foregroundStyle(AppTheme.secondaryText)

                Text(strings.backTapQuickAdd)
                    .font(.system(size: 12 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.tertiaryText)

                VStack(alignment: .leading, spacing: 8) {
                    instructionRow(strings.backTapStepOpenShortcuts)
                    instructionRow(strings.backTapStepCreateShortcut)
                    instructionRow(strings.backTapStepAddOpenURLs)
                    instructionRow(strings.backTapStepUseQuickAddURL)
                    instructionRow(strings.backTapStepOpenAccessibility)
                    instructionRow(strings.backTapStepSelectShortcut)
                }

                Button {
                    onCopyQuickAddURL?()
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text(strings.copyQuickAddURL)
                    }
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.background)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.primaryText)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.copyQuickAddURL)
                .accessibilityHint(strings.backTapDescription)

                Button {
                    onCopyPrefillURLExample?()
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text(strings.copyPrefillURLExample)
                    }
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.cardFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.cardBorder, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.copyPrefillURLExample)
                .accessibilityHint(strings.backTapDescription)

                Button {
                    dismiss()
                    onOpenQuickAdd?()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(strings.openQuickAdd)
                    }
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.cardFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.cardBorder, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.openQuickAdd)
                .accessibilityHint(strings.backTapDescription)

                Button {
                    dismiss()
                    DispatchQueue.main.async {
                        onOpenQuickAddRoute?()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.right.circle")
                        Text(strings.openQuickAddRoute)
                    }
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.cardFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.cardBorder, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.openQuickAddRoute)
                .accessibilityHint(strings.backTapDescription)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var resetCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.resetTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Text(strings.resetConfirmationMessage)
                    .font(.system(size: 15 * scale))
                    .foregroundStyle(AppTheme.secondaryText)

                Button {
                    showResetConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text(strings.deleteAllData)
                    }
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.background)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.primaryText)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.deleteAllData)
                .accessibilityHint(strings.resetConfirmationMessage)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var versionCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text(strings.aboutTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Text(strings.aboutDescription)
                    .font(.system(size: 15 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
                Text("\(strings.versionLabel) \(versionText)")
                    .font(.system(size: 13 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func instructionRow(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13 * appTextSize.scale))
            .foregroundStyle(AppTheme.secondaryText)
    }

    private var notificationStatusRow: some View {
        HStack(spacing: 8) {
            Image(systemName: notificationStatusIconName)
                .foregroundStyle(notificationStatusColor)
            Text(notificationStatusText)
                .font(.system(size: 13 * scale, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
        }
    }

    private func notificationFeedbackBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.orange)
            Text(message)
                .font(.system(size: 13 * scale))
                .foregroundStyle(AppTheme.primaryText)
            Spacer()
            Button(strings.openSystemSettings) {
                openSystemSettings()
            }
            .font(.system(size: 13 * scale, weight: .semibold))
            .foregroundStyle(AppTheme.primaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.orange.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            return strings.notificationsStatusEnabled
        case .denied:
            return strings.notificationsStatusDenied
        case .notDetermined:
            return strings.notificationsStatusNotDetermined
        @unknown default:
            return strings.notificationsStatusDisabled
        }
    }

    private var notificationStatusIconName: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            return "bell.badge.fill"
        case .denied:
            return "bell.slash.fill"
        case .notDetermined:
            return "bell"
        @unknown default:
            return "bell.slash"
        }
    }

    private var notificationStatusColor: Color {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .secondary
        }
    }

    private var dailyCheckInTimeBinding: Binding<Date> {
        Binding(
            get: {
                calendarDate(hour: dailyCheckInHour, minute: dailyCheckInMinute)
            },
            set: { newValue in
                dailyCheckInHour = Calendar.current.component(.hour, from: newValue)
                dailyCheckInMinute = Calendar.current.component(.minute, from: newValue)
                Task { await handleNotificationSettingsChanged() }
            }
        )
    }

    private var weeklyDigestTimeBinding: Binding<Date> {
        Binding(
            get: {
                calendarDate(hour: weeklyDigestHour, minute: weeklyDigestMinute)
            },
            set: { newValue in
                weeklyDigestHour = Calendar.current.component(.hour, from: newValue)
                weeklyDigestMinute = Calendar.current.component(.minute, from: newValue)
                Task { await handleNotificationSettingsChanged() }
            }
        )
    }

    @MainActor
    private func handleNotificationSettingsChanged() async {
        guard !isSyncingNotificationSettings else { return }
        isSyncingNotificationSettings = true
        defer { isSyncingNotificationSettings = false }

        let status = await LocalNotificationService.shared.authorizationStatus()
        notificationStatus = status

        if localNotificationsEnabled {
            if status == .notDetermined {
                let granted = await LocalNotificationService.shared.requestAuthorization()
                notificationStatus = await LocalNotificationService.shared.authorizationStatus()
                if !granted || notificationStatus == .denied {
                    disableNotificationsWithFeedback()
                    return
                }
            } else if status == .denied {
                disableNotificationsWithFeedback()
                return
            }
            notificationFeedback = nil
        } else {
            notificationFeedback = nil
            LocalNotificationService.shared.cancelAllPocketLeakNotifications()
        }

        onSyncNotifications?()
    }

    @MainActor
    private func refreshNotificationStatus() async {
        notificationStatus = await LocalNotificationService.shared.authorizationStatus()
    }

    @MainActor
    private func disableNotificationsWithFeedback() {
        localNotificationsEnabled = false
        dailyCheckInEnabled = false
        goalWarningsEnabled = false
        weeklyDigestReminderEnabled = false
        notificationFeedback = strings.notificationsPermissionDeniedMessage
        LocalNotificationService.shared.cancelAllPocketLeakNotifications()
    }

    private func calendarDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? .now
    }

    private func weekdayTitle(for weekday: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        guard symbols.indices.contains(weekday - 1) else { return "\(weekday)" }
        return symbols[weekday - 1]
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

private extension AppAppearance {
    var title: String {
        switch self {
        case .system:
            return "System"
        case .dark:
            return "Dark"
        case .light:
            return "Light"
        }
    }
}

private extension AppTextSize {
    var title: String {
        switch self {
        case .xs:
            return "XS"
        case .small:
            return "Small"
        case .medium:
            return "Medium"
        case .large:
            return "Large"
        case .xl:
            return "XL"
        }
    }
}

private extension AppLanguage {
    var title: String {
        switch self {
        case .english:
            return "English"
        case .spanish:
            return "Spanish"
        }
    }
}
