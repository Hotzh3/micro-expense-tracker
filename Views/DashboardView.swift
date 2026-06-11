import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @State private var didAnimateIn = false

    private let donutPalette: [Color] = [
        .blue,
        .orange,
        .green,
        .pink,
        .purple,
        .teal,
        .red,
        .indigo,
        .mint,
        .yellow
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeaderView(
                    title: strings.dashboardHeader,
                    subtitle: strings.dashboardHeaderSubtitle,
                    showsSettingsButton: true
                )

                if viewModel.expenses.isEmpty {
                    emptyStateSection
                } else {
                    overviewSection
                    spendingBreakdownSection
                    trendsSection
                    signalsSection
                    recentActivitySection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 0)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            guard !didAnimateIn else { return }
            if reduceMotion {
                didAnimateIn = true
            } else {
                withAnimation(AppMotion.standard) {
                    didAnimateIn = true
                }
            }
        }
        .animation(AppMotion.animation(reduceMotion: reduceMotion, fallback: AppMotion.standard), value: didAnimateIn)
    }

    private var emptyStateSection: some View {
        EmptyStateView(
            title: strings.dashboardEmptyStateTitle,
            message: strings.dashboardEmptyStateMessage,
            actionTitle: strings.dashboardEmptyStateAction,
            action: {
                guard let url = URL(string: "pocketleak://quick-add") else { return }
                openURL(url)
            }
        )
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: strings.dashboardOverviewSection)

            GlassCardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(strings.dashboardQuickSnapshotTitle)
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            MetricCardView(
                                title: "Today",
                                value: amount(viewModel.todayTotal),
                                subtitle: "Local storage total"
                            )
                            MetricCardView(
                                title: "This Week",
                                value: amount(viewModel.weekTotal),
                                subtitle: "Local storage total"
                            )
                        }
                        HStack(spacing: 12) {
                            MetricCardView(
                                title: "This Month",
                                value: amount(viewModel.monthTotal),
                                subtitle: "Local storage total"
                            )
                            MetricCardView(
                                title: "Top Category",
                                value: viewModel.topCategory?.displayName ?? "—",
                                subtitle: "By spending this month"
                            )
                        }
                        HStack(spacing: 12) {
                            MetricCardView(
                                title: "Largest Expense",
                                value: viewModel.largestExpenseThisMonthText,
                                subtitle: viewModel.largestExpenseThisMonthSubtitle
                            )
                            MetricCardView(
                                title: "Average Expense",
                                value: amount(viewModel.averageExpenseAmount),
                                subtitle: "Across all saved expenses"
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .opacity(didAnimateIn ? 1 : 0)
            .offset(y: didAnimateIn ? 0 : 8)
        }
    }

    private var spendingBreakdownSection: some View {
        let summaries = viewModel.dashboardCategorySummariesSafe
        let total = summaries.reduce(0) { $0 + $1.total }
        let segments = donutSegments(from: summaries, total: total)

        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: strings.dashboardBreakdownSection,
                subtitle: strings.dashboardBreakdownSubtitle
            )

            GlassCardView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(strings.dashboardCategoryDistributionTitle)
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)

                    if segments.isEmpty || total <= 0 {
                        Text(strings.dashboardNoCategoryDistribution)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    } else {
                        donutSummaryView(segments: segments, total: total)
                        categoryDistributionList(segments: segments)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .opacity(didAnimateIn ? 1 : 0)
            .offset(y: didAnimateIn ? 0 : 8)
        }
    }

    private var trendsSection: some View {
        let trendPoints = viewModel.dashboardTrendPointsSafe
        let maxTotal = max(trendPoints.map(\.total).max() ?? 0, 1)
        let hasTrendData = trendPoints.contains { $0.total > 0 }

        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: strings.dashboardTrendsSection,
                subtitle: strings.dashboardTrendsSubtitle
            )

            GlassCardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(strings.dashboardRecentTrendTitle)
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)

                    if trendPoints.isEmpty || !hasTrendData {
                        Text(strings.dashboardNoRecentTrend)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    } else {
                        recentTrendBars(trendPoints: trendPoints, maxTotal: maxTotal)

                        HStack {
                            Text("14 days")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                            Text("Total \(amount(trendPoints.reduce(0) { $0 + $1.total }))")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .opacity(didAnimateIn ? 1 : 0)
            .offset(y: didAnimateIn ? 0 : 8)
        }
    }

    private var signalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: strings.dashboardSignalsSection)

            VStack(spacing: 12) {
                if let signal = viewModel.dashboardSignalSafe {
                    dashboardSignalCard(signal)
                }

                categoryBudgetSignalCard
                recurringSignalCard
                smartInsightCard
            }
            .opacity(didAnimateIn ? 1 : 0)
            .offset(y: didAnimateIn ? 0 : 8)
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: strings.dashboardRecentActivitySection)

            recentExpensesCard
                .opacity(didAnimateIn ? 1 : 0)
                .offset(y: didAnimateIn ? 0 : 8)
        }
    }

    private func sectionHeader(title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func amount(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    private func percentage(_ value: Double) -> String {
        String(format: "%.0f%%", safePercent(value) * 100)
    }

    private func safePercent(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }

    private func donutSegments(from summaries: [ExpenseViewModel.DashboardCategorySummary], total: Double) -> [DashboardDonutSegment] {
        guard total.isFinite, total > 0 else { return [] }

        var running: Double = 0
        let lastIndex = summaries.indices.last

        return summaries.enumerated().compactMap { index, summary in
            let percent = safePercent(summary.total / total)
            guard percent > 0 else { return nil }

            let start = min(max(running, 0), 1)
            let rawEnd = index == lastIndex ? 1 : running + percent
            let end = min(max(rawEnd, start), 1)
            guard end > start else { return nil }

            running = end

            return DashboardDonutSegment(
                id: "\(summary.key)-\(index)",
                label: summary.categoryName,
                amount: summary.total,
                count: summary.count,
                percent: percent,
                color: donutColor(at: index),
                start: CGFloat(start),
                end: CGFloat(end)
            )
        }
    }

    private func donutColor(at index: Int) -> Color {
        donutPalette[index % donutPalette.count]
    }

    @ViewBuilder
    private func donutSummaryView(segments: [DashboardDonutSegment], total: Double) -> some View {
        VStack(spacing: 14) {
            ZStack {
                ForEach(segments) { segment in
                    Circle()
                        .trim(from: segment.start, to: segment.end)
                        .stroke(
                            segment.color,
                            style: StrokeStyle(lineWidth: 20, lineCap: .butt, lineJoin: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }

                Circle()
                    .fill(AppTheme.background)
                    .frame(width: 98, height: 98)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    )

                VStack(spacing: 3) {
                    Text(amount(total))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(strings.goalsPeriodThisMonth)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .frame(height: 214)
            .padding(.horizontal, 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(strings.dashboardCategoryDistributionTitle)
            .accessibilityValue(amount(total))
        }
    }

    @ViewBuilder
    private func categoryDistributionList(segments: [DashboardDonutSegment]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(segment.color)
                            .frame(width: 10, height: 10)
                        Text(segment.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                            .lineLimit(1)
                        Spacer()
                        Text(amount(segment.amount))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                    }

                    HStack {
                        Text("\(segment.count) expense\(segment.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Spacer()
                        Text(percentage(segment.percent))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(segment.color)
                    }

                    ProgressView(value: safePercent(segment.percent))
                        .progressViewStyle(.linear)
                        .tint(segment.color)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func recentTrendBars(trendPoints: [ExpenseViewModel.DashboardTrendPoint], maxTotal: Double) -> some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(trendPoints.enumerated()), id: \.offset) { _, point in
                let ratio = point.total.isFinite && maxTotal.isFinite && maxTotal > 0 ? min(max(point.total / maxTotal, 0), 1) : 0

                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AppTheme.primaryText.opacity(0.85))
                        .frame(height: max(4, 110 * CGFloat(ratio)))
                    Text(point.date.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 160)
    }

    private func dashboardSignalCard(_ signal: ExpenseViewModel.DashboardSignal) -> some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.dashboardSignalTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(signal.accentColor.opacity(0.16))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: signal.kind == .budget ? "chart.line.uptrend.xyaxis" : "chart.pie.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(signal.accentColor)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(signal.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                        Text(signal.detail)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Text(strings.dashboardSignalSubtitle)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var categoryBudgetSignalCard: some View {
        let signal = viewModel.dashboardCategoryBudgetSignalSafe

        return GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.insightsCategoryBudgetTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                if let signal {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 12) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(signal.accentColor.opacity(0.16))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: signal.statusText == strings.categoryBudgetsStatusOver ? "exclamationmark.triangle.fill" : signal.statusText == strings.categoryBudgetsStatusWatch ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(signal.accentColor)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(signal.categoryName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Text("\(signal.cadenceText) • \(signal.statusText)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Spent \(signal.spentText)")
                                Spacer()
                                Text("Limit \(signal.limitText)")
                            }
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)

                            HStack {
                                Text("Remaining \(signal.remainingText)")
                                Spacer()
                                Text(signal.percentText)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(signal.accentColor)
                            }
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)

                            ProgressView(value: safePercent(signal.progressFraction))
                                .progressViewStyle(.linear)
                                .tint(signal.accentColor)
                        }
                    }
                } else {
                    Text(strings.noCategoryBudgetsMessage)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var recurringSignalCard: some View {
        let signal = viewModel.dashboardRecurringSignalSafe

        return GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.dashboardRecurringSignalTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                if let signal {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(signal.accentColor.opacity(0.16))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(signal.accentColor)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(signal.merchant)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Text("\(signal.cadenceText) • Due \(signal.dueDateText)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()
                        }

                        HStack {
                            Text(signal.categoryName)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                            Text(signal.amountText)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                        }
                    }
                } else {
                    Text(strings.noRecurringExpensesMessage)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var smartInsightCard: some View {
        let insight = viewModel.dashboardSmartInsightSafe

        return GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.dashboardSmartInsightTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                if let insight {
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(insight.accentColor.opacity(0.16))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: insight.symbolName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(insight.accentColor)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(insight.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text(insight.message)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }

                        Spacer()
                    }
                } else {
                    Text(strings.noSmartInsightMessage)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var recentExpensesCard: some View {
        let recentExpenses = Array(viewModel.expenses.filter { $0.amount.isFinite && $0.amount > 0 }.sorted { $0.date > $1.date }.prefix(5))

        return GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Expenses")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                if recentExpenses.isEmpty {
                    Text("Your latest expenses will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    VStack(spacing: 10) {
                        ForEach(recentExpenses) { expense in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(expense.merchant.isEmpty ? expense.category.displayName : expense.merchant)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)
                                        .lineLimit(1)
                                    Text(expense.category.displayName)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(amount(expense.amount))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)
                                    Text(expense.date.formatted(date: .abbreviated, time: .omitted))
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
}

private struct DashboardDonutSegment: Identifiable {
    let id: String
    let label: String
    let amount: Double
    let count: Int
    let percent: Double
    let color: Color
    let start: CGFloat
    let end: CGFloat
}
