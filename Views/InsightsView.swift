import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeaderView(
                    title: "Insights",
                    subtitle: "See patterns without charts while keeping the UI calm and lightweight."
                )

                VStack(spacing: 12) {
                    if viewModel.expenses.isEmpty {
                        EmptyStateView(
                            title: "No insights yet",
                            message: "Add a few expenses and the app will surface spending patterns here."
                        )
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCardView(title: "Average Daily Spend", value: currency(viewModel.averageDailySpend), subtitle: "Current month pace")
                        MetricCardView(title: "Projected Monthly Spend", value: currency(viewModel.projectedMonthlySpend), subtitle: "Based on current pace")
                        MetricCardView(title: "Most Frequent Category", value: viewModel.mostFrequentCategory?.displayName ?? "—", subtitle: "By expense count")
                        MetricCardView(title: "Highest Expense", value: highestExpenseValue, subtitle: highestExpenseSubtitle)
                        MetricCardView(title: "Logged Expenses", value: "\(viewModel.totalExpenseCount)", subtitle: "All local entries")
                        MetricCardView(title: "Average Expense", value: currency(viewModel.averageExpenseAmount), subtitle: "Across all entries")
                    }

                    GlassCardView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Micro-Expense Insight")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            Text(viewModel.insightText)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GlassCardView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category Breakdown")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)

                            if viewModel.categoryBreakdown.isEmpty {
                                Text("No category breakdown yet.")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondaryText)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(viewModel.categoryBreakdown) { item in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(item.category.displayName)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(AppTheme.primaryText)
                                                Spacer()
                                                Text(currency(item.total))
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(AppTheme.primaryText)
                                            }
                                            Text("\(item.count) expense\(item.count == 1 ? "" : "s")")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.secondaryText)
                                        }
                                        .padding(.bottom, 12)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private var highestExpenseValue: String {
        guard let highestExpense = viewModel.highestExpense else { return "—" }
        return currency(highestExpense.amount)
    }

    private var highestExpenseSubtitle: String {
        guard let highestExpense = viewModel.highestExpense else {
            return "No saved expenses yet"
        }

        let merchant = highestExpense.merchant.isEmpty ? highestExpense.category.displayName : highestExpense.merchant
        return merchant
    }

    private func currency(_ amount: Double) -> String {
        String(format: "$%.2f", amount)
    }
}
