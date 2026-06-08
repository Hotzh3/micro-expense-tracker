import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    @Binding var appearanceSelection: AppAppearance
    @Binding var textSizeSelection: AppTextSize
    @Binding var languageSelection: AppLanguage

    let versionText: String
    let onOpenHistory: (() -> Void)?
    let onOpenGoals: (() -> Void)?
    let onOpenQuickAdd: (() -> Void)?
    let onCopyQuickAddURL: (() -> Void)?
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
                Button(strings.deleteAllExpenses, role: .destructive) {
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
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.primaryText)
                    )
                }
                .buttonStyle(.plain)

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

                VStack(alignment: .leading, spacing: 8) {
                    instructionRow("1. Open Shortcuts.")
                    instructionRow("2. Create a Shortcut.")
                    instructionRow("3. Add Open URLs.")
                    instructionRow("4. Use pocketleak://quick-add.")
                    instructionRow("5. Go to Settings > Accessibility > Touch > Back Tap.")
                    instructionRow("6. Assign the Shortcut to Double Tap.")
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
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.primaryText)
                    )
                }
                .buttonStyle(.plain)

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
                        Text(strings.resetLocalData)
                    }
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.primaryText)
                    )
                }
                .buttonStyle(.plain)
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
