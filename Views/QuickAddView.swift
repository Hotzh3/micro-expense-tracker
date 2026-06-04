import SwiftUI

struct QuickAddView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel

    var body: some View {
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
        }
    }
}
