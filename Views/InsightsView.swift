import Charts
import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.presentRecurringExpenses) private var presentRecurringExpenses
    @State private var didAnimateIn = false
    @State private var weeklyDigestShareURL: URL?
    private let shareCardRenderer = ShareCardRenderer()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeaderView(
                    title: strings.insightsHeader,
                    subtitle: strings.smartInsightsSubtitle,
                    showsSettingsButton: true
                )

                VStack(spacing: 12) {
                    if !viewModel.smartAlerts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(strings.smartAlertsTitle)
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            Text(strings.smartAlertsSubtitle)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)

                            VStack(spacing: 12) {
                                ForEach(viewModel.smartAlerts) { alert in
                                    SmartAlertCardView(
                                        alert: alert,
                                        strings: strings,
                                        dismissAction: {
                                            viewModel.dismissSmartAlert(id: alert.id)
                                        }
                                    )
                                }
                            }
                        }
                        .opacity(didAnimateIn ? 1 : 0)
                        .offset(y: didAnimateIn ? 0 : 8)
                    }

                    WeeklyDigestView(
                        digest: viewModel.weeklyDigest,
                        strings: strings,
                        shareURL: weeklyDigestShareURL
                    )

                    if let categoryBudget = viewModel.primaryCategoryBudgetOverview {
                        categoryBudgetInsightCard(for: categoryBudget)
                            .opacity(didAnimateIn ? 1 : 0)
                            .offset(y: didAnimateIn ? 0 : 8)
                    }

                    recurringExpensesCard
                        .opacity(didAnimateIn ? 1 : 0)
                        .offset(y: didAnimateIn ? 0 : 8)

                    if !viewModel.expenses.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(strings.smartInsightsTitle)
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)

                            VStack(spacing: 12) {
                                ForEach(Array(viewModel.smartInsights.prefix(4))) { insight in
                                    SmartInsightCardView(insight: insight)
                                }
                            }
                        }
                        .opacity(didAnimateIn ? 1 : 0)
                        .offset(y: didAnimateIn ? 0 : 8)
                    }

                    if !viewModel.spendingComparisons.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(strings.trendsTitle)
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            Text(strings.trendsSubtitle)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)

                            VStack(spacing: 12) {
                                ForEach(viewModel.spendingComparisons) { comparison in
                                    SpendingComparisonCardView(
                                        comparison: comparison,
                                        strings: strings
                                    )
                                }
                            }
                        }
                        .opacity(didAnimateIn ? 1 : 0)
                        .offset(y: didAnimateIn ? 0 : 8)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCardView(title: "Average Daily Spend", value: viewModel.displayCurrency(viewModel.averageDailySpend), subtitle: "Current month pace")
                        MetricCardView(title: "Projected Monthly Spend", value: viewModel.displayCurrency(viewModel.projectedMonthlySpend), subtitle: "Based on current pace")
                        MetricCardView(title: "Most Frequent Category", value: viewModel.mostFrequentCategory?.displayName ?? "—", subtitle: "By expense count")
                        MetricCardView(title: "Highest Expense", value: highestExpenseValue, subtitle: highestExpenseSubtitle)
                        MetricCardView(title: "Logged Expenses", value: "\(viewModel.totalExpenseCount)", subtitle: "All local entries")
                        MetricCardView(title: "Average Expense", value: viewModel.displayCurrency(viewModel.averageExpenseAmount), subtitle: "Across all entries")
                    }
                    .opacity(didAnimateIn ? 1 : 0)
                    .offset(y: didAnimateIn ? 0 : 8)

                    GlassCardView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Weekly Totals")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)

                            if viewModel.hasWeeklyTrendData {
                                Chart(viewModel.weeklySpendTrendData) { point in
                                    BarMark(
                                        x: .value("Week", point.weekStart),
                                        y: .value("Total", point.total)
                                    )
                                    .foregroundStyle(AppTheme.primaryText)
                                }
                                .chartLegend(.hidden)
                                .accessibilityHidden(true)
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
                                .frame(height: 180)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(strings.insightsWeeklyTotalsTitle)
                                .accessibilityValue(viewModel.weeklyTrendAccessibilitySummary)
                            } else {
                                Text("Add a little more history before weekly totals are shown.")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .opacity(didAnimateIn ? 1 : 0)
                    .offset(y: didAnimateIn ? 0 : 8)

                    GlassCardView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category Breakdown")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)

                            if viewModel.categoryBreakdown.isEmpty {
                                Text(strings.insightsNoCategoryBreakdown)
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
                                                Text(viewModel.displayCurrency(item.total))
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
                        .accessibilityElement(children: .contain)
                    }
                    .opacity(didAnimateIn ? 1 : 0)
                    .offset(y: didAnimateIn ? 0 : 8)
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
            await refreshWeeklyDigestShareURL()
        }
    }

    @MainActor
    private func refreshWeeklyDigestShareURL() async {
        weeklyDigestShareURL = shareCardRenderer.shareURL(
            for: .weeklySummary,
            viewModel: viewModel,
            strings: strings
        )
    }

    private func categoryBudgetInsightCard(for overview: ExpenseViewModel.CategoryBudgetOverview) -> some View {
        let statusText = viewModel.categoryBudgetStatusText(for: overview.status)
        let insightText = viewModel.categoryBudgetInsightText(for: overview)

        return GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.insightsCategoryBudgetTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Text(strings.insightsCategoryBudgetSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)

                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(overview.status.tintColor.opacity(0.14))
                        Image(systemName: overview.status == .over ? "exclamationmark.octagon.fill" : "target")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(overview.status.tintColor)
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(overview.budget.category.displayName) • \(statusText)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Text(insightText)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var recurringExpensesCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.insightsRecurringLeaksTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Text(strings.insightsRecurringLeaksSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)

                if let nextRecurring = viewModel.nextRecurringExpense {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.cardFill)
                            Image(systemName: "repeat")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                        }
                        .frame(width: 40, height: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.recurringExpenseTitle(for: nextRecurring))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            Text(viewModel.recurringExpenseNextDueText(for: nextRecurring))
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text("\(viewModel.recurringExpenseCadenceText(for: nextRecurring.cadence)) • \(viewModel.displayCurrency(nextRecurring.amount))")
                                .font(.caption)
                                .foregroundStyle(AppTheme.tertiaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    Text(strings.recurringExpensesNoUpcomingMessage)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Button {
                    presentRecurringExpenses()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "repeat")
                        Text(strings.recurringExpensesCreateButton)
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var highestExpenseValue: String {
        guard let highestExpense = viewModel.highestExpense else { return "—" }
        return viewModel.displayCurrency(highestExpense.amount)
    }

    private var highestExpenseSubtitle: String {
        guard let highestExpense = viewModel.highestExpense else {
            return "No saved expenses yet"
        }

        let merchant = highestExpense.merchant.isEmpty ? highestExpense.category.displayName : highestExpense.merchant
        return merchant
    }

}
