import SwiftUI

struct QuickAddView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GlassCardView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Capture a micro-expense in under 10 seconds.")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Amount")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.tertiaryText)
                                TextField("0.00", text: $viewModel.amountText)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppTheme.primaryText)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(Color.white.opacity(0.04))
                                    )
                            }
                        }
                    }

                    GlassCardView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Category")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
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
                            Text("Merchant / Note")
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

                    PrimaryButton(title: "Save Expense") {
                        viewModel.saveDraftExpense()
                    }
                }
                .padding(16)
                .safeAreaPadding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            if let feedback = viewModel.saveFeedback {
                banner(for: feedback)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: viewModel.saveFeedback)
        .onChange(of: viewModel.amountText) { _, _ in viewModel.clearSaveFeedback() }
        .onChange(of: viewModel.merchantText) { _, _ in viewModel.clearSaveFeedback() }
        .onChange(of: viewModel.noteText) { _, _ in viewModel.clearSaveFeedback() }
        .onChange(of: viewModel.selectedCategory) { _, _ in viewModel.clearSaveFeedback() }
    }

    @ViewBuilder
    private func banner(for feedback: ExpenseViewModel.Feedback) -> some View {
        HStack(spacing: 10) {
            Image(systemName: feedback.isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .foregroundStyle(feedback.isError ? Color.white : Color.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(feedback.isError ? "Could not save" : "Expense saved")
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
