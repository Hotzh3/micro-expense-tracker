import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.expenses.isEmpty {
                    EmptyStateView(
                        title: "No history yet",
                        message: "Saved expenses will appear here once you add your first one."
                    )
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.expenses.sorted(by: { $0.date > $1.date })) { expense in
                            HistoryRow(expense: expense)
                        }
                    }
                }
            }
            .padding(16)
            .safeAreaPadding(.bottom, 24)
        }
    }
}

private struct HistoryRow: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    let expense: Expense

    var body: some View {
        GlassCardView {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(formattedAmount(expense.amount))
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText)
                        Text(expense.category.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(AppTheme.chipFill)
                            )
                    }

                    if !expense.merchant.isEmpty {
                        Text(expense.merchant)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.primaryText)
                    }

                    if !expense.note.isEmpty {
                        Text(expense.note)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Text(expense.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(AppTheme.tertiaryText)
                }

                Spacer()

                Button {
                    if let index = viewModel.expenses.firstIndex(where: { $0.id == expense.id }) {
                        viewModel.deleteExpense(at: IndexSet(integer: index))
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(AppTheme.cardFill)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func formattedAmount(_ amount: Double) -> String {
        String(format: "$%.2f", amount)
    }
}
