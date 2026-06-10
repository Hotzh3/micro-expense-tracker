import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.appTextSize) private var appTextSize: AppTextSize
    @AppStorage(AppPreferenceKeys.hapticsEnabled) private var hapticsEnabled = true

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
    let onShowOnboardingAgain: (() -> Void)?
    let onResetLocalData: () -> Void

    @State private var showResetConfirmation = false

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
                Text(versionText)
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
