import SwiftUI
import UIKit

struct QuickAddImportCardView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.appTextSize) private var appTextSize: AppTextSize
    @FocusState.Binding var focusedField: QuickAddView.Field?

    private var scale: CGFloat {
        appTextSize.scale
    }

    var body: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.pasteTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                Text(strings.pasteDescription)
                    .font(.system(size: 14 * scale))
                    .foregroundStyle(AppTheme.secondaryText)

                TextEditor(text: $viewModel.importText)
                    .id(QuickAddView.Field.importText)
                    .scrollContentBackground(.hidden)
                    .focused($focusedField, equals: .importText)
                    .font(.system(size: 15 * scale))
                    .foregroundColor(AppTheme.primaryText)
                    .tint(AppTheme.primaryText)
                    .accentColor(AppTheme.primaryText)
                    .accessibilityLabel(strings.pasteTitle)
                    .accessibilityHint(strings.pasteDescription)
                    .frame(minHeight: 120)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.inputFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.inputBorder, lineWidth: 1)
                            )
                    )

                Button(action: pasteFromClipboard) {
                    clipboardButtonLabel
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.pasteFromClipboard)
                .accessibilityHint(strings.pasteDescription)

                Button(action: parseImportedText) {
                    parseButtonLabel
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.parseTextButton)
                .accessibilityHint(strings.parseNoResultMessage)

                if let parseFeedback = viewModel.parseFeedback {
                    feedbackBanner(for: parseFeedback)
                }
            }
        }
    }

    private var clipboardButtonLabel: some View {
        HStack {
            Image(systemName: "doc.on.clipboard")
            Text(strings.pasteFromClipboard)
        }
        .font(.system(size: 15 * scale, weight: .semibold))
        .foregroundStyle(AppTheme.primaryText)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 44)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
        )
    }

    private var parseButtonLabel: some View {
        HStack {
            Image(systemName: "wand.and.stars")
            Text(strings.parseTextButton)
        }
        .font(.system(size: 15 * scale, weight: .semibold))
        .foregroundStyle(AppTheme.background)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.primaryText)
        )
    }

    private func pasteFromClipboard() {
        let clipboardText = UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let clipboardText, !clipboardText.isEmpty else {
            viewModel.setParseFeedback(message: strings.clipboardEmptyMessage, isError: true)
            return
        }

        viewModel.importText = clipboardText
        viewModel.parsedExpense = nil
        viewModel.clearParseFeedback()
        focusedField = .importText
    }

    private func parseImportedText() {
        viewModel.parseImportedText()
    }

    @ViewBuilder
    private func feedbackBanner(for feedback: ExpenseViewModel.Feedback) -> some View {
        HStack(spacing: 10) {
            Image(systemName: feedback.isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .foregroundStyle(feedback.isError ? Color.white : Color.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(feedback.isError ? strings.needsAttention : strings.ready)
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(feedback.message)
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(feedback.isError ? Color.red.opacity(0.2) : Color.green.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(feedback.isError ? Color.red.opacity(0.55) : Color.green.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
    }
}
