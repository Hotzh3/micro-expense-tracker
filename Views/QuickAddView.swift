import SwiftUI

struct QuickAddView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeaderView(
                    title: "Quick Add",
                    subtitle: "Capture a leak fast, or paste transaction text for a privacy-safe parse."
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

                            Text("Paste a bank alert or transaction message. Pocket Leak extracts what it can, then lets you edit before saving.")
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
                        }
                    }

                    PrimaryButton(title: "Save Expense") {
                        viewModel.saveDraftExpense()
                    }

                    if let saveFeedback = viewModel.saveFeedback {
                        feedbackBanner(for: saveFeedback)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .animation(.easeOut(duration: 0.2), value: viewModel.saveFeedback)
        .animation(.easeOut(duration: 0.2), value: viewModel.parseFeedback)
        .onChange(of: viewModel.amountText) { _, _ in viewModel.clearSaveFeedback() }
        .onChange(of: viewModel.merchantText) { _, _ in viewModel.clearSaveFeedback() }
        .onChange(of: viewModel.noteText) { _, _ in viewModel.clearSaveFeedback() }
        .onChange(of: viewModel.selectedCategory) { _, _ in viewModel.clearSaveFeedback() }
        .onChange(of: viewModel.importText) { _, _ in viewModel.clearParseFeedback() }
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
}
