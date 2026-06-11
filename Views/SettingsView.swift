import SwiftUI
import UIKit
import UserNotifications
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.appTextSize) private var appTextSize: AppTextSize
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @AppStorage(AppPreferenceKeys.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(AppPreferenceKeys.smartAlertsEnabled) private var smartAlertsEnabled = true
    @AppStorage(AppPreferenceKeys.appLockEnabled) private var appLockEnabled = false
    @AppStorage(AppPreferenceKeys.requireFaceIDOnLaunch) private var requireFaceIDOnLaunch = true
    @AppStorage(AppPreferenceKeys.privacyModeHideAmounts) private var privacyModeHideAmounts = false
    @AppStorage(AppPreferenceKeys.hideAmountsInWidgets) private var hideAmountsInWidgets = false
    @AppStorage(AppPreferenceKeys.localNotificationsEnabled) private var localNotificationsEnabled = false
    @AppStorage(AppPreferenceKeys.dailyCheckInEnabled) private var dailyCheckInEnabled = false
    @AppStorage(AppPreferenceKeys.goalWarningsEnabled) private var goalWarningsEnabled = false
    @AppStorage(AppPreferenceKeys.weeklyDigestReminderEnabled) private var weeklyDigestReminderEnabled = false
    @AppStorage(AppPreferenceKeys.dailyCheckInHour) private var dailyCheckInHour = 18
    @AppStorage(AppPreferenceKeys.dailyCheckInMinute) private var dailyCheckInMinute = 0
    @AppStorage(AppPreferenceKeys.weeklyDigestWeekday) private var weeklyDigestWeekday = 1
    @AppStorage(AppPreferenceKeys.weeklyDigestHour) private var weeklyDigestHour = 9
    @AppStorage(AppPreferenceKeys.weeklyDigestMinute) private var weeklyDigestMinute = 0
    @AppStorage(AppPreferenceKeys.hasSeenOnboarding) private var hasSeenOnboarding = false

    @Binding var appearanceSelection: AppAppearance
    @Binding var textSizeSelection: AppTextSize
    @Binding var languageSelection: AppLanguage

    let versionText: String
    let onOpenHistory: (() -> Void)?
    let onOpenGoals: (() -> Void)?
    let onOpenQuickAdd: (() -> Void)?
    let onOpenRecurringExpenses: (() -> Void)? = nil
    let onCopyQuickAddURL: (() -> Void)?
    let onCopyPrefillURLExample: (() -> Void)?
    let onOpenQuickAddRoute: (() -> Void)?
    let onSyncNotifications: (() -> Void)?
    let onShowOnboardingAgain: (() -> Void)?
    let onResetLocalData: () -> Void

    @State private var showResetConfirmation = false
    @State private var showBackupImportConfirmation = false
    @State private var showBackupImporter = false
    @State private var showShortcutsGuide = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var notificationFeedback: String?
    @State private var backupFeedback: String?
    @State private var backupFeedbackIsError = false
    @State private var backupExport: DataBackupExport?
    @State private var pendingBackupDocument: DataBackupDocument?
    @State private var isSyncingNotificationSettings = false
    @State private var showLoadDemoConfirmation = false
    @State private var showResetDemoConfirmation = false
    @State private var showStressDemoConfirmation = false
    @State private var showStressClearConfirmation = false
#if DEBUG
    @State private var selectedStressScenario: StressDemoScenario = .thirtyDays
#endif
    private let appLockService = AppLockService.shared

    private let backupService = DataBackupService()

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
                    backupCard
                    demoModeCard
#if DEBUG
                    stressToolsCard
#endif
                    exportCard
                    recurringCard
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
            .confirmationDialog(
                strings.demoModeTitle,
                isPresented: $showLoadDemoConfirmation,
                titleVisibility: .visible
            ) {
                Button(strings.loadDemoData, role: .destructive) {
                    viewModel.loadDemoData()
                    backupFeedback = strings.demoDataLoaded
                    backupFeedbackIsError = false
                }
                Button(strings.cancel, role: .cancel) {}
            } message: {
                Text(strings.demoDataWarning)
            }
            .confirmationDialog(
                strings.demoModeTitle,
                isPresented: $showResetDemoConfirmation,
                titleVisibility: .visible
            ) {
                Button(strings.resetDemoData, role: .destructive) {
                    if viewModel.resetDemoData() {
                        backupFeedback = strings.demoDataCleared
                        backupFeedbackIsError = false
                    } else {
                        showResetConfirmation = true
                    }
                }
                Button(strings.cancel, role: .cancel) {}
            } message: {
                Text(strings.demoDataWarning)
            }
            .confirmationDialog(
                strings.backupTitle,
                isPresented: $showBackupImportConfirmation,
                titleVisibility: .visible
            ) {
                Button(strings.backupImportMerge) {
                    restorePendingBackup(mode: .merge)
                }
                Button(strings.backupImportReplace, role: .destructive) {
                    restorePendingBackup(mode: .replace)
                }
                Button(strings.cancel, role: .cancel) {}
            } message: {
                Text(backupImportMessage)
            }
#if DEBUG
            .confirmationDialog(
                "Generate demo data?",
                isPresented: $showStressDemoConfirmation,
                titleVisibility: .visible,
                presenting: selectedStressScenario
            ) { scenario in
                Button("Generate \(scenario.title)", role: .destructive) {
                    viewModel.loadStressDemoData(days: scenario.days, expensesPerDay: scenario.dailyExpenseCount)
                    backupFeedback = "Generated \(scenario.days) days of demo data"
                    backupFeedbackIsError = false
                    prepareBackupExport()
                }
                Button(strings.cancel, role: .cancel) {}
            } message: { scenario in
                Text("This will replace current expenses with \(scenario.title.lowercased()) of synthetic data.")
            }
            .confirmationDialog(
                "Clear demo data?",
                isPresented: $showStressClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear demo expenses", role: .destructive) {
                    viewModel.clearAllExpenses()
                    backupFeedback = "Demo expenses cleared"
                    backupFeedbackIsError = false
                    prepareBackupExport()
                }
                Button(strings.cancel, role: .cancel) {}
            } message: {
                Text("This removes the generated demo expenses from the local store.")
            }
#endif
            .fileImporter(
                isPresented: $showBackupImporter,
                allowedContentTypes: [.json]
            ) { result in
                handleBackupImport(result: result)
            }
            .sheet(isPresented: $showShortcutsGuide) {
                ShortcutsGuideView(
                    onCopyQuickAddURL: onCopyQuickAddURL,
                    onCopyPrefillURLExample: onCopyPrefillURLExample,
                    onOpenQuickAddRoute: onOpenQuickAddRoute
                )
                .environment(\.pocketLeakStrings, strings)
                .environment(\.appTextSize, appTextSize)
            }
            .task {
                await refreshNotificationStatus()
                await MainActor.run {
                    syncPrivacyPreferences()
                }
            }
            .task(id: backupSignature) {
                prepareBackupExport()
            }
            .onChange(of: appLockEnabled) { _, _ in
                syncPrivacyPreferences()
            }
            .onChange(of: requireFaceIDOnLaunch) { _, _ in
                syncPrivacyPreferences()
            }
            .onChange(of: privacyModeHideAmounts) { _, _ in
                syncPrivacyPreferences()
            }
            .onChange(of: hideAmountsInWidgets) { _, _ in
                syncPrivacyPreferences()
            }
            .onChange(of: scenePhase) { _, newValue in
                guard newValue == .active else { return }
                Task {
                    await refreshNotificationStatus()
                    prepareBackupExport()
                    await MainActor.run {
                        syncPrivacyPreferences()
                    }
                }
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
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.privacyTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                Text(strings.privacyNote)
                    .font(.system(size: 15 * scale))
                    .foregroundStyle(AppTheme.secondaryText)

                Divider()
                    .overlay(AppTheme.cardBorder.opacity(0.5))

                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $appLockEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(strings.enableAppLock)
                                .font(.system(size: 15 * scale, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text(strings.appLockDescription)
                                .font(.system(size: 13 * scale))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .tint(AppTheme.primaryText)

                    Toggle(isOn: $requireFaceIDOnLaunch) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(strings.requireFaceIDOnLaunch)
                                .font(.system(size: 15 * scale, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text(appLockService.biometryDescription())
                                .font(.system(size: 13 * scale))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .tint(AppTheme.primaryText)
                    .disabled(!appLockEnabled)

                    Toggle(isOn: $privacyModeHideAmounts) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(strings.privacyModeHideAmountsTitle)
                                .font(.system(size: 15 * scale, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text(strings.privacyModeHideAmountsDescription)
                                .font(.system(size: 13 * scale))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .tint(AppTheme.primaryText)

                    Toggle(isOn: $hideAmountsInWidgets) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(strings.hideAmountsInWidgetsTitle)
                                .font(.system(size: 15 * scale, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text(strings.hideAmountsInWidgetsDescription)
                                .font(.system(size: 13 * scale))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .tint(AppTheme.primaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var backupCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(strings.backupTitle)
                        .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(strings.backupDescription)
                        .font(.system(size: 15 * scale))
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(strings.backupLocalOnlyNote)
                        .font(.system(size: 13 * scale))
                        .foregroundStyle(AppTheme.tertiaryText)
                }

                VStack(spacing: 10) {
                    if let backupExport {
                        ShareLink(item: backupExport.fileURL) {
                            actionButtonLabel(title: strings.exportBackup, systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            prepareBackupExport()
                        } label: {
                            actionButtonLabel(title: strings.exportBackup, systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.plain)
                        .disabled(true)
                    }

                    Button {
                        showBackupImporter = true
                    } label: {
                        actionButtonLabel(title: strings.importBackup, systemImage: "tray.and.arrow.down")
                    }
                    .buttonStyle(.plain)
                }

                if let backupFeedback {
                    backupFeedbackBanner(message: backupFeedback, isError: backupFeedbackIsError)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var demoModeCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(strings.demoModeTitle)
                        .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(strings.demoDataWarning)
                        .font(.system(size: 15 * scale))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                VStack(spacing: 10) {
                    Button {
                        showLoadDemoConfirmation = true
                    } label: {
                        actionButtonLabel(title: strings.loadDemoData, systemImage: "sparkles")
                    }
                    .buttonStyle(.plain)

                    Button {
                        showResetDemoConfirmation = true
                    } label: {
                        actionButtonLabel(title: strings.resetDemoData, systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.plain)

                    Button {
                        showResetConfirmation = true
                    } label: {
                        actionButtonLabel(title: strings.clearDemoData, systemImage: "trash")
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

#if DEBUG
    private enum StressDemoScenario: String, CaseIterable, Identifiable {
        case thirtyDays
        case sixtyDays
        case ninetyDays

        var id: String { rawValue }

        var days: Int {
            switch self {
            case .thirtyDays:
                return 30
            case .sixtyDays:
                return 60
            case .ninetyDays:
                return 90
            }
        }

        var title: String {
            switch self {
            case .thirtyDays:
                return "30 days demo data"
            case .sixtyDays:
                return "60 days demo data"
            case .ninetyDays:
                return "90 days demo data"
            }
        }

        var dailyExpenseCount: Int {
            5
        }
    }

    private var stressToolsCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Stress / Demo Tools")
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                Text("Generate synthetic expense history to test launch speed, dashboard rendering, history filters, and export behavior.")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(AppTheme.secondaryText)

                Button {
                    selectedStressScenario = .thirtyDays
                    showStressDemoConfirmation = true
                } label: {
                    actionButtonLabel(title: "Generate 30 days demo data", systemImage: "sparkles")
                }
                .buttonStyle(.plain)

                Button {
                    selectedStressScenario = .sixtyDays
                    showStressDemoConfirmation = true
                } label: {
                    actionButtonLabel(title: "Generate 60 days demo data", systemImage: "sparkles")
                }
                .buttonStyle(.plain)

                Button {
                    selectedStressScenario = .ninetyDays
                    showStressDemoConfirmation = true
                } label: {
                    actionButtonLabel(title: "Generate 90 days demo data", systemImage: "sparkles")
                }
                .buttonStyle(.plain)

                Button {
                    showStressClearConfirmation = true
                } label: {
                    actionButtonLabel(title: "Clear demo data", systemImage: "trash")
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
#endif

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

    private var recurringCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.recurringExpensesTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Text(strings.recurringExpensesSubtitle)
                    .font(.system(size: 15 * scale))
                    .foregroundStyle(AppTheme.secondaryText)

                Button {
                    dismiss()
                    DispatchQueue.main.async {
                        onOpenRecurringExpenses?()
                    }
                } label: {
                    HStack {
                        Image(systemName: "repeat")
                        Text(strings.recurringExpensesCreateButton)
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
                .accessibilityLabel(strings.recurringExpensesCreateButton)
                .accessibilityHint(strings.recurringExpensesSubtitle)
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
                    showShortcutsGuide = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(strings.openShortcutsGuide)
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
                .accessibilityLabel(strings.openShortcutsGuide)
                .accessibilityHint(strings.backTapDescription)

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
                        Text(strings.testQuickAddLink)
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
                .accessibilityLabel(strings.testQuickAddLink)
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

    private func backupFeedbackBanner(message: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(isError ? Color.orange : Color.green)
            Text(message)
                .font(.system(size: 13 * scale))
                .foregroundStyle(AppTheme.primaryText)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill((isError ? Color.orange : Color.green).opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke((isError ? Color.orange : Color.green).opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func actionButtonLabel(title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(title)
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

    private var backupImportMessage: String {
        guard let pendingBackupDocument else {
            return strings.backupImportConfirmationMessage
        }

        let summary = String(
            format: strings.backupImportSummaryTemplate,
            pendingBackupDocument.expenses.count,
            pendingBackupDocument.goals.activeGoals.count,
            pendingBackupDocument.categoryBudgets.count,
            pendingBackupDocument.recurringExpenses.count
        )
        return "\(summary)\n\n\(strings.backupImportConfirmationMessage)"
    }

    private var backupSignature: String {
        let expenseSignature = viewModel.expenses
            .map { "\($0.id.uuidString):\($0.amount):\($0.date.timeIntervalSince1970):\($0.category.id.uuidString):\($0.merchant):\($0.note):\($0.source.rawValue)" }
            .joined(separator: ",")

        let goalSignature = [
            viewModel.weeklyGoal.map { "\($0.id.uuidString):\($0.limit):\($0.updatedAt.timeIntervalSince1970)" } ?? "nil",
            viewModel.monthlyGoal.map { "\($0.id.uuidString):\($0.limit):\($0.updatedAt.timeIntervalSince1970)" } ?? "nil"
        ]
        .joined(separator: "|")

        let budgetSignature = viewModel.categoryBudgets
            .map { "\($0.id.uuidString):\($0.category.id.uuidString):\($0.cadence.rawValue):\($0.limit):\($0.updatedAt.timeIntervalSince1970):\($0.isActive)" }
            .joined(separator: ",")

        let recurringSignature = viewModel.recurringExpenses
            .map { "\($0.id.uuidString):\($0.merchant):\($0.amount):\($0.category.id.uuidString):\($0.cadence.rawValue):\($0.nextDueDate.timeIntervalSince1970):\($0.updatedAt.timeIntervalSince1970):\($0.isActive)" }
            .joined(separator: ",")

        let settingsSignature = [
            appearanceSelection.rawValue,
            textSizeSelection.rawValue,
            languageSelection.rawValue,
            String(hapticsEnabled),
            String(smartAlertsEnabled),
            String(localNotificationsEnabled),
            String(dailyCheckInEnabled),
            String(goalWarningsEnabled),
            String(weeklyDigestReminderEnabled),
            "\(dailyCheckInHour):\(dailyCheckInMinute)",
            "\(weeklyDigestWeekday):\(weeklyDigestHour):\(weeklyDigestMinute)",
            String(hasSeenOnboarding)
        ]
        .joined(separator: "|")

        return [expenseSignature, goalSignature, budgetSignature, recurringSignature, settingsSignature].joined(separator: "||")
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

    private func prepareBackupExport() {
        let settings = currentBackupSettingsSnapshot()
        backupExport = backupService.export(
            expenses: viewModel.expenses,
            goals: SpendingGoals(weekly: viewModel.weeklyGoal, monthly: viewModel.monthlyGoal),
            categoryBudgets: viewModel.categoryBudgets,
            recurringExpenses: viewModel.recurringExpenses,
            settings: settings
        )
    }

    private func currentBackupSettingsSnapshot() -> DataBackupSettingsSnapshot {
        DataBackupSettingsSnapshot(
                appearance: appearanceSelection.rawValue,
                textSize: textSizeSelection.rawValue,
                language: languageSelection.rawValue,
                hapticsEnabled: hapticsEnabled,
                smartAlertsEnabled: smartAlertsEnabled,
                appLockEnabled: appLockEnabled,
                requireFaceIDOnLaunch: requireFaceIDOnLaunch,
                privacyModeHideAmounts: privacyModeHideAmounts,
                hideAmountsInWidgets: hideAmountsInWidgets,
                localNotificationsEnabled: localNotificationsEnabled,
                dailyCheckInEnabled: dailyCheckInEnabled,
                goalWarningsEnabled: goalWarningsEnabled,
                weeklyDigestReminderEnabled: weeklyDigestReminderEnabled,
            dailyCheckInHour: dailyCheckInHour,
            dailyCheckInMinute: dailyCheckInMinute,
            weeklyDigestWeekday: weeklyDigestWeekday,
            weeklyDigestHour: weeklyDigestHour,
            weeklyDigestMinute: weeklyDigestMinute,
            hasSeenOnboarding: hasSeenOnboarding
        )
    }

    private func handleBackupImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                if let document = backupService.loadBackup(from: url) {
                    pendingBackupDocument = document
                    showBackupImportConfirmation = true
                    backupFeedback = nil
                    backupFeedbackIsError = false
                } else {
                    backupFeedback = strings.backupImportFailed
                    backupFeedbackIsError = true
                }
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            guard let document = backupService.loadBackup(from: url) else {
                backupFeedback = strings.backupImportFailed
                backupFeedbackIsError = true
                return
            }

            pendingBackupDocument = document
            showBackupImportConfirmation = true
            backupFeedback = nil
            backupFeedbackIsError = false
        case .failure:
            backupFeedback = strings.backupImportFailed
            backupFeedbackIsError = true
        }
    }

    private func restorePendingBackup(mode: DataBackupRestoreMode) {
        guard let document = pendingBackupDocument else { return }

        if let settings = document.settings {
            applyImportedSettings(settings)
        }

        let summary = viewModel.restoreBackup(document, mode: mode)
        pendingBackupDocument = nil
        showBackupImportConfirmation = false
        backupFeedbackIsError = false
        backupFeedback = summaryMessage(for: summary)
        prepareBackupExport()
    }

    private func applyImportedSettings(_ settings: DataBackupSettingsSnapshot) {
        appearanceSelection = AppAppearance(rawValue: settings.appearance) ?? appearanceSelection
        textSizeSelection = AppTextSize(rawValue: settings.textSize) ?? textSizeSelection
        languageSelection = AppLanguage(rawValue: settings.language) ?? languageSelection
        hapticsEnabled = settings.hapticsEnabled
        smartAlertsEnabled = settings.smartAlertsEnabled
        if let appLockEnabled = settings.appLockEnabled {
            self.appLockEnabled = appLockEnabled
        }
        if let requireFaceIDOnLaunch = settings.requireFaceIDOnLaunch {
            self.requireFaceIDOnLaunch = requireFaceIDOnLaunch
        }
        if let privacyModeHideAmounts = settings.privacyModeHideAmounts {
            self.privacyModeHideAmounts = privacyModeHideAmounts
        }
        if let hideAmountsInWidgets = settings.hideAmountsInWidgets {
            self.hideAmountsInWidgets = hideAmountsInWidgets
        }
        localNotificationsEnabled = settings.localNotificationsEnabled
        dailyCheckInEnabled = settings.dailyCheckInEnabled
        goalWarningsEnabled = settings.goalWarningsEnabled
        weeklyDigestReminderEnabled = settings.weeklyDigestReminderEnabled
        dailyCheckInHour = settings.dailyCheckInHour
        dailyCheckInMinute = settings.dailyCheckInMinute
        weeklyDigestWeekday = settings.weeklyDigestWeekday
        weeklyDigestHour = settings.weeklyDigestHour
        weeklyDigestMinute = settings.weeklyDigestMinute
        hasSeenOnboarding = settings.hasSeenOnboarding
    }

    private func summaryMessage(for summary: DataBackupRestorationSummary) -> String {
        let dataSummary = String(
            format: strings.backupImportSummaryTemplate,
            summary.expenseCount,
            summary.goalCount,
            summary.categoryBudgetCount,
            summary.recurringExpenseCount
        )

        return "\(dataSummary) \(strings.backupImportSuccess)"
    }

    @MainActor
    private func syncPrivacyPreferences() {
        viewModel.updatePrivacyPreferences(
            hideAmounts: privacyModeHideAmounts,
            hideAmountsInWidgets: hideAmountsInWidgets
        )
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
