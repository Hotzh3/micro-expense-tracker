import SwiftUI

struct QuickAddView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ScreenHeaderView(
                        title: "Quick Add",
                        subtitle: "Capture a leak fast, or paste transaction text for a privacy-safe parse.",
                        showsSettingsButton: true
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        GlassCardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Capture a micro-expense in under 10 seconds.")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.primaryText)

                                amountField
                            }
                        }

                        GlassCardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Category")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.primaryText)

                                Text("Pick the closest match first. You can always adjust it later.")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondaryText)

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 10)], spacing: 8) {
                                    ForEach(viewModel.categories) { category in
                                        CategoryPillView(category: category, isSelected: viewModel.selectedCategory == category)
                                            .onTapGesture {
                                                viewModel.selectedCategory = category
                                            }
                                    }
                                }
                            }
                        }

                        GlassCardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Details")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.primaryText)

                                TextField("Optional merchant", text: $viewModel.merchantText)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(AppTheme.primaryText)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.white.opacity(0.04))
                                    )

                                TextField("Optional note", text: $viewModel.noteText)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(AppTheme.primaryText)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.white.opacity(0.04))
                                    )
                            }
                        }

                        GlassCardView {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Paste Notification Text")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.primaryText)

                                Text("Paste a bank alert or transaction message. Pocket Leak only parses text you paste yourself, keeping the flow privacy-safe.")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondaryText)

                                TextEditor(text: $viewModel.importText)
                                    .scrollContentBackground(.hidden)
                                    .font(.body)
                                    .foregroundStyle(AppTheme.primaryText)
                                    .frame(minHeight: 96)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.white.opacity(0.04))
                                    )

                                Button {
                                    viewModel.parseImportedText()
                                } label: {
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                        Text("Parse Text")
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(AppTheme.primaryText)
                                    )
                                }
                                .buttonStyle(.plain)

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
                                            Text("Use Parsed Expense")
                                        }
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(AppTheme.primaryText)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        PrimaryButton(title: "Save Expense") {
                            viewModel.saveDraftExpense()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 0)
                .padding(.bottom, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: 14)
            }
            .animation(.easeOut(duration: 0.2), value: viewModel.saveFeedback)
            .animation(.easeOut(duration: 0.2), value: viewModel.parseFeedback)
            .onChange(of: viewModel.amountText) { _, _ in viewModel.clearSaveFeedback() }
            .onChange(of: viewModel.merchantText) { _, _ in viewModel.clearSaveFeedback() }
            .onChange(of: viewModel.noteText) { _, _ in viewModel.clearSaveFeedback() }
            .onChange(of: viewModel.selectedCategory) { _, _ in viewModel.clearSaveFeedback() }
            .onChange(of: viewModel.importText) { _, _ in viewModel.clearParseFeedback() }

            if viewModel.saveFeedback != nil {
                HStack {
                    Spacer(minLength: 0)
                    saveToast()
                    Spacer(minLength: 0)
                }
                .padding(.top, 10)
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .allowsHitTesting(false)
            }
        }
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)

            TextField("0.00", text: $viewModel.amountText)
                .keyboardType(.decimalPad)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
        }
    }

    @ViewBuilder
    private func feedbackBanner(for feedback: ExpenseViewModel.Feedback) -> some View {
        HStack(spacing: 10) {
            Image(systemName: feedback.isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .foregroundStyle(feedback.isError ? Color.white : Color.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(feedback.isError ? "Needs attention" : "Ready")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(feedback.message)
                    .font(.caption)
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

    private func saveToast() -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.green)
            Text("Expense saved")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.green.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.green.opacity(0.48), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 10)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func parsedPreviewCard(for parsedExpense: ExpenseParseResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Parsed Preview")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Review the extracted details before saving.")
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
                previewRow(label: "Amount", value: parsedExpense.amount.map { String(format: "$%.2f", $0) } ?? "—")
                previewRow(label: "Merchant", value: parsedExpense.merchant.isEmpty ? "—" : parsedExpense.merchant)
                previewRow(label: "Category", value: parsedExpense.category.displayName)
                previewRow(label: "Source", value: "Parsed text")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
        )
    }

    private func previewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
        }
    }
}
