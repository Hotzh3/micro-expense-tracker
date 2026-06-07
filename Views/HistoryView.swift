import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @State private var timeFilter: HistoryTimeFilter = .all
    @State private var selectedCategoryID: UUID? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeaderView(
                    title: "History",
                    subtitle: "Review saved leaks by time range and category."
                )

                VStack(spacing: 12) {
                    filterCard

                    if viewModel.expenses.isEmpty {
                        EmptyStateView(
                            title: "No expenses yet",
                            message: "Add your first micro-expense from Quick Add."
                        )
                    } else if filteredExpenses.isEmpty {
                        EmptyStateView(
                            title: "No matching expenses",
                            message: "Try a different category or time filter."
                        )
                        .overlay(alignment: .bottom) {
                            Button("Reset filters") {
                                resetFilters()
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                            .padding(.top, 8)
                            .offset(y: 18)
                        }
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredExpenses) { expense in
                                HistoryRow(expense: expense)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private var filteredExpenses: [Expense] {
        let category = selectedCategoryID.flatMap { id in
            viewModel.categories.first(where: { $0.id == id })
        }
        return viewModel.expenses(matching: category, timeFilter: timeFilter)
    }

    private var selectedCategoryLabel: String {
        guard let selectedCategoryID,
              let category = viewModel.categories.first(where: { $0.id == selectedCategoryID }) else {
            return "All Categories"
        }
        return category.displayName
    }

    private var filterCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("History")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Filter saved expenses by time range and category.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Picker("Time range", selection: $timeFilter) {
                    ForEach(HistoryTimeFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                Menu {
                    Button("All Categories") {
                        selectedCategoryID = nil
                    }

                    Divider()

                    ForEach(viewModel.categories) { category in
                        Button(category.displayName) {
                            selectedCategoryID = category.id
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Category")
                                .font(.caption)
                                .foregroundStyle(AppTheme.tertiaryText)
                            Text(selectedCategoryLabel)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                        }

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    )
                }
                .buttonStyle(.plain)

                HStack {
                    Text("\(filteredExpenses.count) expense\(filteredExpenses.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    Button("Reset") {
                        resetFilters()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func resetFilters() {
        timeFilter = .all
        selectedCategoryID = nil
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
                    viewModel.deleteExpense(id: expense.id)
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
                .accessibilityLabel("Delete expense")
            }
        }
    }

    private func formattedAmount(_ amount: Double) -> String {
        String(format: "$%.2f", amount)
    }
}
