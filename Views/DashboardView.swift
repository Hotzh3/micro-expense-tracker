import Charts
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.presentSettings) private var presentSettings
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAnimateIn = false
    @State private var shareCardURLs: [ShareCardVariant: URL] = [:]
    private let shareCardRenderer = ShareCardRenderer()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeaderView(
                    title: strings.dashboardHeader,
                    subtitle: strings.dashboardHeaderSubtitle,
                    showsSettingsButton: true
                )

                VStack(spacing: 12) {
                    if let alert = viewModel.primarySmartAlert {
                        SmartAlertCardView(
                            alert: alert,
                            strings: strings,
                            dismissAction: {
                                viewModel.dismissSmartAlert(id: alert.id)
                            }
                        )
                        .opacity(didAnimateIn ? 1 : 0)
                        .offset(y: didAnimateIn ? 0 : 8)
                    }

                    if viewModel.expenses.isEmpty {
                        VStack(spacing: 12) {
                            EmptyStateView(
                                title: strings.dashboardEmptyStateTitle,
                                message: strings.dashboardEmptyStateMessage,
                                actionTitle: strings.dashboardEmptyStateAction,
                                action: {
                                    guard let url = URL(string: "pocketleak://quick-add") else { return }
                                    openURL(url)
                                }
                            )

                            Button {
                                presentSettings()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "gearshape")
                                    Text(strings.openSettings)
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(AppTheme.cardFill)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(AppTheme.cardBorder, lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        HStack {
                            Text(strings.dashboardQuickSnapshotTitle)
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            shareSummaryMenu
                        }
                    }

                    if !viewModel.expenses.isEmpty {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            MetricCardView(title: "Today", value: amount(viewModel.todayTotal), subtitle: "Local storage total")
                            MetricCardView(title: "This Week", value: amount(viewModel.weekTotal), subtitle: "Local storage total")
                            MetricCardView(title: "This Month", value: amount(viewModel.monthTotal), subtitle: "Local storage total")
                            MetricCardView(title: "Top Category", value: viewModel.topCategory?.displayName ?? "—", subtitle: "By spending this month")
                            MetricCardView(title: "Largest Expense", value: viewModel.largestExpenseThisMonthText, subtitle: viewModel.largestExpenseThisMonthSubtitle)
                            MetricCardView(title: "Average Expense", value: amount(viewModel.averageExpenseAmount), subtitle: "Across all saved expenses")
                        }
                        .opacity(didAnimateIn ? 1 : 0)
                        .offset(y: didAnimateIn ? 0 : 8)

                        goalsSummaryCard
                            .opacity(didAnimateIn ? 1 : 0)
                            .offset(y: didAnimateIn ? 0 : 8)
                        if let forecast = viewModel.primaryGoalForecast,
                           forecast.status != .safe {
                            goalForecastRiskCard(for: forecast)
                                .opacity(didAnimateIn ? 1 : 0)
                                .offset(y: didAnimateIn ? 0 : 8)
                        }
                        if let comparison = viewModel.primarySpendingComparison {
                            SpendingComparisonCardView(
                                comparison: comparison,
                                strings: strings,
                                compact: true
                            )
                            .opacity(didAnimateIn ? 1 : 0)
                            .offset(y: didAnimateIn ? 0 : 8)
                        }
                        categoryDistributionCard
                            .opacity(didAnimateIn ? 1 : 0)
                            .offset(y: didAnimateIn ? 0 : 8)
                        recentTrendCard
                            .opacity(didAnimateIn ? 1 : 0)
                            .offset(y: didAnimateIn ? 0 : 8)

                        GlassCardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(strings.dashboardSignalTitle)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.primaryText)
                                Text(strings.dashboardSignalSubtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondaryText)

                                if let insight = viewModel.primarySmartInsight {
                                    HStack(alignment: .top, spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(insight.type.accentColor.opacity(0.14))
                                            Image(systemName: insight.type.iconName)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(insight.type.accentColor)
                                        }
                                        .frame(width: 40, height: 40)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(insight.title)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(AppTheme.primaryText)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.85)
                                            Text(insight.message)
                                                .font(.subheadline)
                                                .foregroundStyle(AppTheme.secondaryText)
                                                .lineLimit(3)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                } else {
                                    Text(viewModel.insightText)
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
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
        .task(id: viewModel.shareCardSnapshotSignature) {
            await prepareShareCardURLs()
        }
    }

    private func amount(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    @ViewBuilder
    private var shareSummaryMenu: some View {
        Menu {
            shareLink(for: .weeklySummary)
            shareLink(for: .monthlySummary)
            shareLink(for: .goalProgress)
            shareLink(for: .topCategory)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                Text(strings.shareSummaryButton)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(AppTheme.chipFill)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    )
            )
        }
        .menuStyle(.borderlessButton)
    }

    @ViewBuilder
    private func shareLink(for variant: ShareCardVariant) -> some View {
        if let item = shareCardURLs[variant] {
            ShareLink(item: item) {
                Label(title(for: variant), systemImage: icon(for: variant))
            }
        } else {
            Button {
                // Intentionally disabled until the image is prepared.
            } label: {
                Label(title(for: variant), systemImage: icon(for: variant))
            }
            .disabled(true)
        }
    }

    @MainActor
    private func prepareShareCardURLs() async {
        let weekly = shareCardRenderer.shareURL(for: .weeklySummary, viewModel: viewModel, strings: strings)
        let monthly = shareCardRenderer.shareURL(for: .monthlySummary, viewModel: viewModel, strings: strings)
        let goal = shareCardRenderer.shareURL(for: .goalProgress, viewModel: viewModel, strings: strings)
        let top = shareCardRenderer.shareURL(for: .topCategory, viewModel: viewModel, strings: strings)

        var urls: [ShareCardVariant: URL] = [:]
        if let weekly { urls[.weeklySummary] = weekly }
        if let monthly { urls[.monthlySummary] = monthly }
        if let goal { urls[.goalProgress] = goal }
        if let top { urls[.topCategory] = top }
        shareCardURLs = urls
    }

    private func title(for variant: ShareCardVariant) -> String {
        switch variant {
        case .weeklySummary:
            return strings.shareSummaryWeeklyCardTitle
        case .monthlySummary:
            return strings.shareSummaryMonthlyCardTitle
        case .goalProgress:
            return strings.shareSummaryGoalCardTitle
        case .topCategory:
            return strings.shareSummaryTopCategoryCardTitle
        }
    }

    private func icon(for variant: ShareCardVariant) -> String {
        switch variant {
        case .weeklySummary:
            return "calendar"
        case .monthlySummary:
            return "calendar.badge.clock"
        case .goalProgress:
            return "target"
        case .topCategory:
            return "chart.pie.fill"
        }
    }

    private var categoryDistributionCard: some View {
        let categoryShares = viewModel.categorySharesThisMonth

        return GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.dashboardCategoryDistributionTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                if categoryShares.isEmpty {
                    Text(strings.dashboardNoCategoryDistribution)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    VStack(spacing: 16) {
                        ZStack {
                            Chart(categoryShares) { share in
                                SectorMark(
                                    angle: .value("Spend", share.total),
                                    innerRadius: .ratio(0.66),
                                    angularInset: 2
                                )
                                .foregroundStyle(share.category.accentColor)
                            }
                            .chartLegend(.hidden)
                            .accessibilityHidden(true)

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
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(strings.dashboardCategoryDistributionTitle)
                        .accessibilityValue(viewModel.categoryDistributionAccessibilitySummary)

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(categoryShares) { share in
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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(strings.dashboardRecentTrendTitle)
            .accessibilityValue(viewModel.recentTrendAccessibilitySummary)
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
                        .accessibilityLabel(strings.dashboardGoalsCtaButton)
                        .accessibilityHint(strings.dashboardGoalsCtaSubtitle)
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
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(summary.cadence == .weekly ? strings.goalsWeeklyTitle : strings.goalsMonthlyTitle)
                            .accessibilityValue(viewModel.goalAccessibilityValue(for: summary.cadence))
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
            return Color(red: 0.19, green: 0.64, blue: 0.38)
        case .closeToLimit:
            return Color(red: 0.92, green: 0.69, blue: 0.15)
        case .limitReached:
            return Color(red: 0.86, green: 0.25, blue: 0.24)
        case .none:
            return Color(red: 0.19, green: 0.64, blue: 0.38)
        }
    }

    private func goalForecastRiskCard(for forecast: GoalForecast) -> some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(forecast.status.tintColor.opacity(0.14))
                        Image(systemName: forecast.status.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(forecast.status.tintColor)
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.goalForecastHeadline(for: forecast.goalType) ?? strings.goalsForecastTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        if let subtitle = viewModel.goalForecastHelperText(for: forecast.goalType) {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text(viewModel.goalForecastSummaryText(for: forecast.goalType) ?? "")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
