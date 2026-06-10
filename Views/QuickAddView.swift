import SwiftUI
import UIKit

struct QuickAddView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.appTextSize) private var appTextSize: AppTextSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @FocusState private var focusedField: Field?

    private var scale: CGFloat {
        appTextSize.scale
    }

    private enum Field {
        case amount
        case merchant
        case note
        case importText
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ScreenHeaderView(
                            title: strings.quickAddHeader,
                            subtitle: strings.quickAddIntro,
                            showsSettingsButton: true
                        )

                        VStack(alignment: .leading, spacing: 12) {
                            GlassCardView {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(strings.quickAddIntro)
                                        .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                                        .foregroundStyle(AppTheme.primaryText)

                                    amountField
                                }
                            }

                            GlassCardView {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(strings.categoryTitle)
                                        .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                                        .foregroundStyle(AppTheme.primaryText)

                                    Text(strings.categorySubtitle)
                                        .font(.system(size: 14 * scale))
                                        .foregroundStyle(AppTheme.secondaryText)

                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 10)], spacing: 8) {
                                        ForEach(viewModel.categories) { category in
                                            CategoryPillView(category: category, isSelected: viewModel.selectedCategory == category)
                                                .onTapGesture {
                                                    guard viewModel.selectedCategory != category else { return }
                                                    HapticsService.shared.lightTap()
                                                    viewModel.selectedCategory = category
                                                }
                                        }
                                    }
                                }
                            }

                            GlassCardView {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(strings.detailsTitle)
                                        .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                                        .foregroundStyle(AppTheme.primaryText)

                                    TextField(
                                        "",
                                        text: $viewModel.merchantText,
                                        prompt: Text(strings.merchantPlaceholder)
                                            .foregroundStyle(AppTheme.tertiaryText)
                                    )
                                        .id(Field.merchant)
                                        .textFieldStyle(.plain)
                                        .foregroundColor(AppTheme.primaryText)
                                        .tint(AppTheme.primaryText)
                                        .accentColor(AppTheme.primaryText)
                                        .focused($focusedField, equals: .merchant)
                                        .submitLabel(.next)
                                        .font(.system(size: 15 * scale))
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 14)
                                        .accessibilityLabel(strings.merchantPlaceholder)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(AppTheme.inputFill)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                        .stroke(AppTheme.inputBorder, lineWidth: 1)
                                                )
                                        )

                                    TextField(
                                        "",
                                        text: $viewModel.noteText,
                                        prompt: Text(strings.notePlaceholder)
                                            .foregroundStyle(AppTheme.tertiaryText)
                                    )
                                        .id(Field.note)
                                        .textFieldStyle(.plain)
                                        .foregroundColor(AppTheme.primaryText)
                                        .tint(AppTheme.primaryText)
                                        .accentColor(AppTheme.primaryText)
                                        .focused($focusedField, equals: .note)
                                        .submitLabel(.done)
                                        .font(.system(size: 15 * scale))
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 14)
                                        .accessibilityLabel(strings.notePlaceholder)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(AppTheme.inputFill)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                        .stroke(AppTheme.inputBorder, lineWidth: 1)
                                                )
                                        )
                                }
                            }

                            GlassCardView {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(strings.pasteTitle)
                                        .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                                        .foregroundStyle(AppTheme.primaryText)

                                    Text(strings.pasteDescription)
                                        .font(.system(size: 14 * scale))
                                        .foregroundStyle(AppTheme.secondaryText)

                                    TextEditor(text: $viewModel.importText)
                                        .id(Field.importText)
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

                                    Button {
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
                                    } label: {
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
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(strings.pasteFromClipboard)
                                    .accessibilityHint(strings.pasteDescription)

                                    Button {
                                        viewModel.parseImportedText()
                                    } label: {
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
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(strings.parseTextButton)
                                    .accessibilityHint(strings.parseNoResultMessage)

                                    if let parseFeedback = viewModel.parseFeedback {
                                        feedbackBanner(for: parseFeedback)
                                    }

                                    if let parsedExpense = viewModel.parsedExpense {
                                        parsedPreviewCard(for: parsedExpense)

                                        Button {
                                            viewModel.useParsedExpense()
                                        } label: {
                                            HStack {
                                                Image(systemName: "checkmark.circle.fill")
                                                Text(strings.useParsedExpenseButton)
                                            }
                                            .font(.system(size: 15 * scale, weight: .semibold))
                                            .foregroundStyle(AppTheme.background)
                                            .frame(maxWidth: .infinity)
                                            .frame(minHeight: 44)
                                            .padding(.vertical, 14)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .fill(AppTheme.primaryText)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(strings.useParsedExpenseButton)
                                        .accessibilityHint(strings.parsedPreviewSubtitle)
                                    }
                                }
                            }

                            PrimaryButton(title: strings.saveExpenseButton) {
                                viewModel.saveDraftExpense()
                            }
                            .accessibilityLabel(strings.saveExpenseButton)
                            .accessibilityHint(strings.saveMissingAmountError)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 0)
                    .padding(.bottom, 18)
                }
                .scrollDismissesKeyboard(.interactively)
                .foregroundColor(AppTheme.primaryText)
                .tint(AppTheme.primaryText)
                .accentColor(AppTheme.primaryText)
                .animation(AppMotion.animation(reduceMotion: reduceMotion, fallback: AppMotion.quick), value: viewModel.saveFeedback)
                .animation(AppMotion.animation(reduceMotion: reduceMotion, fallback: AppMotion.quick), value: viewModel.parseFeedback)
                .onChange(of: focusedField) { _, newValue in
                    viewModel.isQuickAddInputFocused = newValue != nil
                    guard let newValue else { return }
                    withAnimation(.easeOut(duration: 0.25)) {
                        scrollProxy.scrollTo(newValue, anchor: .center)
                    }
                }
                .onAppear {
                    viewModel.isQuickAddInputFocused = focusedField != nil
                }
                .onDisappear {
                    viewModel.isQuickAddInputFocused = false
                }
                .onChange(of: viewModel.amountText) { _, _ in viewModel.clearSaveFeedback() }
                .onChange(of: viewModel.merchantText) { _, _ in viewModel.clearSaveFeedback() }
                .onChange(of: viewModel.noteText) { _, _ in viewModel.clearSaveFeedback() }
                .onChange(of: viewModel.selectedCategory) { _, _ in viewModel.clearSaveFeedback() }
                .onChange(of: viewModel.importText) { _, _ in viewModel.clearParseFeedback() }
            }

            if viewModel.saveFeedback != nil {
                HStack {
                    Spacer(minLength: 0)
                    saveToast(for: viewModel.saveFeedback!)
                    Spacer(minLength: 0)
                }
                .padding(.top, 10)
                .padding(.horizontal, 16)
                .transition(AppMotion.transition(reduceMotion: reduceMotion))
                .allowsHitTesting(false)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                switch focusedField {
                case .amount:
                    Spacer()
                    Button(strings.next) {
                        focusedField = .merchant
                    }
                case .merchant:
                    Button(strings.done) {
                        focusedField = nil
                    }
                    Spacer()
                    Button(strings.next) {
                        focusedField = .note
                    }
                case .note:
                    Button(strings.done) {
                        focusedField = nil
                    }
                    Spacer()
                    Button(strings.next) {
                        focusedField = .importText
                    }
                case .importText:
                    Button(strings.done) {
                        focusedField = nil
                    }
                case .none:
                    Spacer()
                    Button(strings.done) {
                        focusedField = nil
                    }
                }
            }
        }
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(strings.amountTitle)
                .font(.system(size: 13 * scale, weight: .semibold))
                .foregroundStyle(AppTheme.tertiaryText)

            TextField(
                "",
                text: $viewModel.amountText,
                prompt: Text("0.00")
                    .foregroundStyle(AppTheme.tertiaryText)
            )
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .amount)
                .submitLabel(.next)
                .font(.system(size: 40 * scale, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.primaryText)
                .tint(AppTheme.primaryText)
                .accentColor(AppTheme.primaryText)
                .accessibilityLabel(strings.amountTitle)
                .accessibilityHint(strings.saveMissingAmountError)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppTheme.inputFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(AppTheme.inputBorder, lineWidth: 1)
                        )
                )
        }
        .id(Field.amount)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(feedback.isError ? strings.needsAttention : strings.ready)
        .accessibilityValue(feedback.message)
    }

    private func saveToast(for feedback: ExpenseViewModel.Feedback) -> some View {
        HStack(spacing: 10) {
            Image(systemName: feedback.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(feedback.isError ? Color.red : Color.green)
            Text(feedback.message)
                .font(.system(size: 15 * scale, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(feedback.isError ? Color.red.opacity(0.14) : Color.green.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(feedback.isError ? Color.red.opacity(0.42) : Color.green.opacity(0.48), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 10)
        .frame(maxWidth: .infinity, alignment: .top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(feedback.isError ? strings.needsAttention : strings.ready)
        .accessibilityValue(feedback.message)
    }

    private func parsedPreviewCard(for parsedExpense: ExpenseParseResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(strings.parsedPreviewTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(strings.parsedPreviewSubtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Text(String(format: "%.0f%%", parsedExpense.confidence * 100))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppTheme.chipFill)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                if let amount = parsedExpense.amount {
                    previewRow(label: strings.amountTitle, value: String(format: "$%.2f", amount))
                }
                if !parsedExpense.merchant.isEmpty {
                    previewRow(label: strings.merchantLabel, value: parsedExpense.merchant)
                }
                previewRow(label: strings.categoryTitle, value: parsedExpense.category.displayName)
                previewRow(label: strings.confidenceLabel, value: String(format: "%.0f%%", parsedExpense.confidence * 100))
                previewRow(label: strings.sourceLabel, value: strings.parsedTextSource)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(strings.parsedPreviewTitle)
        .accessibilityValue(parsedExpense.summary)
    }

    private func previewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13 * appTextSize.scale))
                .foregroundStyle(AppTheme.tertiaryText)
            Spacer()
            Text(value)
                .font(.system(size: 15 * appTextSize.scale, weight: .medium))
                .foregroundStyle(AppTheme.primaryText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
