import SwiftUI

struct ShortcutsGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    let onCopyQuickAddURL: (() -> Void)?
    let onCopyPrefillURLExample: (() -> Void)?
    let onOpenQuickAddRoute: (() -> Void)?

    private var scale: CGFloat {
        appTextSize.scale
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    guideHeader
                    guideSteps
                    quickActions
                    limitationsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(strings.shortcutsGuideTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.done) {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.primaryText)
                }
            }
        }
    }

    private var guideHeader: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text(strings.shortcutsGuideTitle)
                    .font(.system(size: 20 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Text(strings.shortcutsGuideSubtitle)
                    .font(.system(size: 15 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var guideSteps: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text(strings.backTapTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                Text(strings.backTapDescription)
                    .font(.system(size: 14 * scale))
                    .foregroundStyle(AppTheme.secondaryText)

                VStack(alignment: .leading, spacing: 8) {
                    instructionRow(strings.backTapStepOpenShortcuts)
                    instructionRow(strings.backTapStepCreateShortcut)
                    instructionRow(strings.backTapStepAddOpenURLs)
                    instructionRow(strings.backTapStepUseQuickAddURL)
                    instructionRow(strings.backTapStepOpenAccessibility)
                    instructionRow(strings.backTapStepSelectShortcut)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var quickActions: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.openShortcutsGuide)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                VStack(spacing: 10) {
                    Button {
                        onCopyQuickAddURL?()
                    } label: {
                        actionButtonLabel(
                            title: strings.copyQuickAddURL,
                            systemImage: "doc.on.doc",
                            filled: true
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        onCopyPrefillURLExample?()
                    } label: {
                        actionButtonLabel(
                            title: strings.copyPrefillURLExample,
                            systemImage: "doc.on.doc",
                            filled: false
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        dismiss()
                        DispatchQueue.main.async {
                            onOpenQuickAddRoute?()
                        }
                    } label: {
                        actionButtonLabel(
                            title: strings.testQuickAddLink,
                            systemImage: "arrow.up.right.circle",
                            filled: false
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var limitationsCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text(strings.privacyTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Text(strings.backTapDescription)
                    .font(.system(size: 14 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func instructionRow(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13 * scale))
            .foregroundStyle(AppTheme.secondaryText)
    }

    private func actionButtonLabel(title: String, systemImage: String, filled: Bool) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.system(size: 15 * scale, weight: .semibold))
        .foregroundStyle(filled ? AppTheme.background : AppTheme.primaryText)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 44)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(filled ? AppTheme.primaryText : AppTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: filled ? 0 : 1)
                )
        )
    }
}
