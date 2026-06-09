import Charts
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeaderView(
                    title: strings.dashboardHeader,
                    subtitle: strings.dashboardHeaderSubtitle,
                    showsSettingsButton: true
                )

                VStack(spacing: 12) {
                    if viewModel.expenses.isEmpty {
                        EmptyStateView(
                            title: strings.emptyNoExpenses,
                            message: strings.emptyNoExpenses
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

                    goalsSummaryCard
                    categoryDistributionCard
                    recentTrendCard

                    GlassCardView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(strings.dashboardQuickSnapshotTitle)
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
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func amount(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    private var categoryDistributionCard: some View {
        let topShares = viewModel.topCategorySharesThisMonth

        return GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.dashboardCategoryDistributionTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                if topShares.isEmpty {
                    Text(strings.dashboardNoCategoryDistribution)
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
                                .foregroundStyle(share.category.accentColor)
                            }
                            .chartLegend(.hidden)

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
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(share.category.accentColor)
                                                .frame(width: 10, height: 10)
                                            Text(share.category.displayName)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(AppTheme.primaryText)
                                        }
                                        Spacer()
                                        Text("\(percentage(share.percentage))")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppTheme.primaryText)
                                    }

                                    HStack {
                                        Text(amount(share.total))
                                            .font(.caption)
                                            .foregroundStyle(share.category.accentColor)
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
                                                .fill(share.category.accentColor)
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
                Text(strings.dashboardRecentTrendTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Text("A simple 14-day view of how your tracked leaks changed.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)

                if trendData.isEmpty {
                    Text(strings.dashboardNoRecentTrend)
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

    private var goalsSummaryCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.dashboardGoalsTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Text(strings.dashboardGoalsSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)

                if viewModel.goalOverviews.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(strings.dashboardGoalsCtaTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                        Text(strings.dashboardGoalsCtaSubtitle)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)

                        Button {
                            guard let url = URL(string: "pocketleak://goals") else { return }
                            openURL(url)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "target")
                                Text(strings.dashboardGoalsCtaButton)
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AppTheme.primaryText)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.goalOverviews) { summary in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(summary.cadence == .weekly ? strings.goalsWeeklyTitle : strings.goalsMonthlyTitle)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppTheme.primaryText)
                                        Text(summary.statusText)
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                    Spacer()
                                    Text("\(summary.percentUsedText)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)
                                }

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule(style: .continuous)
                                            .fill(AppTheme.cardFill)
                                            .frame(height: 8)
                                        Capsule(style: .continuous)
                                            .fill(progressColor(for: summary.status))
                                            .frame(width: max(8, geometry.size.width * summary.progressFraction), height: 8)
                                    }
                                }
                                .frame(height: 8)

                                HStack {
                                    Text("\(summary.spentText) / \(summary.limitText)")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                    Spacer()
                                    Text("\(strings.goalsRemainingLabel): \(summary.remainingText)")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func progressColor(for status: ExpenseViewModel.GoalStatus) -> Color {
        switch status {
        case .onTrack:
            return .white
        case .closeToLimit:
            return .yellow
        case .limitReached:
            return .red
        case .none:
            return .white
        }
    }
}
