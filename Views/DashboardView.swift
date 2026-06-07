import Charts
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeaderView(
                    title: "Dashboard",
                    subtitle: "Track daily spend, month totals, and the categories leaking the most."
                )

                VStack(spacing: 12) {
                    if viewModel.expenses.isEmpty {
                        EmptyStateView(
                            title: "No expenses yet",
                            message: "Add your first micro-expense from Quick Add."
                        )
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCardView(title: "Today", value: amount(viewModel.todayTotal), subtitle: "Local storage total")
                        MetricCardView(title: "This Week", value: amount(viewModel.weekTotal), subtitle: "Local storage total")
                        MetricCardView(title: "This Month", value: amount(viewModel.monthTotal), subtitle: "Local storage total")
                        MetricCardView(title: "Top Category", value: viewModel.topCategory?.displayName ?? "—", subtitle: "By spending this month")
                        MetricCardView(title: "Expenses This Month", value: "\(viewModel.expenseCountThisMonth)", subtitle: "Saved locally")
                        MetricCardView(title: "Average Expense", value: amount(viewModel.averageExpenseAmount), subtitle: "Across all saved expenses")
                    }

                    categoryChartCard
                    recentTrendCard

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
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.category.displayName)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(AppTheme.primaryText)
                                                Text("\(item.count) expense\(item.count == 1 ? "" : "s")")
                                                    .font(.caption)
                                                    .foregroundStyle(AppTheme.secondaryText)
                                            }

                                            Spacer()

                                            Text(amount(item.total))
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(AppTheme.primaryText)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GlassCardView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Quick Snapshot")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            Text(viewModel.insightText)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
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

    private func amount(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    private var categoryChartCard: some View {
        let chartData = Array(viewModel.categorySpendChartData.prefix(6))

        return GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Spending by Category")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                if chartData.isEmpty {
                    Text("Add a few expenses to see the category mix.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    Chart(chartData) { item in
                        BarMark(
                            x: .value("Amount", item.total),
                            y: .value("Category", item.category.displayName)
                        )
                        .foregroundStyle(AppTheme.primaryText)
                    }
                    .chartLegend(.hidden)
                    .chartXAxis {
                        AxisMarks(position: .bottom, values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .frame(height: CGFloat(max(160, chartData.count * 34)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var recentTrendCard: some View {
        let trendData = viewModel.recentSpendTrendData
        let maxSpend = max(trendData.map(\.total).max() ?? 0, 1)

        return GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Spending Trend")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                if trendData.isEmpty {
                    Text("Add expenses to see your recent spending trend.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    Chart(trendData) { point in
                        LineMark(
                            x: .value("Day", point.date),
                            y: .value("Spend", point.total)
                        )
                        .foregroundStyle(AppTheme.primaryText)
                        PointMark(
                            x: .value("Day", point.date),
                            y: .value("Spend", point.total)
                        )
                        .foregroundStyle(AppTheme.primaryText)
                    }
                    .chartLegend(.hidden)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.month().day(), centered: true)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .chartYScale(domain: 0...maxSpend * 1.15)
                    .frame(height: 180)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
