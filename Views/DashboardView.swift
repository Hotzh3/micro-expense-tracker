import Charts
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeaderView(
                    title: "Dashboard",
                    subtitle: "Track daily spend, month totals, and the categories leaking the most.",
                    showsSettingsButton: true
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
                        MetricCardView(title: "Largest Expense", value: viewModel.largestExpenseThisMonthText, subtitle: viewModel.largestExpenseThisMonthSubtitle)
                        MetricCardView(title: "Average Expense", value: amount(viewModel.averageExpenseAmount), subtitle: "Across all saved expenses")
                    }

                    categoryDistributionCard
                    recentTrendCard

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
            .padding(.top, 0)
            .padding(.bottom, 12)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 14)
        }
    }

    private func amount(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    private var categoryDistributionCard: some View {
        let topShares = viewModel.topCategorySharesThisMonth
        let domain = topShares.map { $0.category.displayName }
        let fillColors: [Color] = [
            Color.white,
            Color.white.opacity(0.76),
            Color.white.opacity(0.52)
        ]

        return GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Category Distribution")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                if topShares.isEmpty {
                    Text("Add a few expenses to see where the leaks cluster.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    VStack(spacing: 16) {
                        ZStack {
                            Chart(topShares) { share in
                                SectorMark(
                                    angle: .value("Spend", share.total),
                                    innerRadius: .ratio(0.66),
                                    angularInset: 2
                                )
                                .foregroundStyle(by: .value("Category", share.category.displayName))
                            }
                            .chartLegend(.hidden)
                            .chartForegroundStyleScale(domain: domain, range: fillColors)

                            VStack(spacing: 2) {
                                Text(amount(viewModel.monthTotal))
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Text("This month")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                        .frame(height: 180)

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(topShares) { share in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(share.category.displayName)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppTheme.primaryText)
                                        Spacer()
                                        Text("\(percentage(share.percentage))")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppTheme.primaryText)
                                    }

                                    HStack {
                                        Text(amount(share.total))
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondaryText)
                                        Spacer()
                                        Text("\(share.count) expense\(share.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }

                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            Capsule(style: .continuous)
                                                .fill(AppTheme.cardFill)
                                                .frame(height: 8)
                                            Capsule(style: .continuous)
                                                .fill(AppTheme.primaryText)
                                                .frame(width: max(8, geometry.size.width * CGFloat(share.percentage / 100)), height: 8)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                            }
                        }

                        Text(viewModel.monthCategorySummaryText)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
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
                Text("A simple 14-day view of how your tracked leaks changed.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)

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

    private func percentage(_ value: Double) -> String {
        String(format: "%.0f%%", value)
    }
}
