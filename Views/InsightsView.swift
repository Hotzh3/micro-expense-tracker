import Charts
import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAnimateIn = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeaderView(
                    title: strings.insightsHeader,
                    subtitle: "See patterns without charts while keeping the UI calm and lightweight.",
                    showsSettingsButton: true
                )

                VStack(spacing: 12) {
                    if viewModel.expenses.isEmpty {
                        EmptyStateView(
                            title: strings.insightsEmptyStateTitle,
                            message: strings.insightsEmptyStateMessage,
                            actionTitle: strings.insightsEmptyStateAction,
                            action: {
                                guard let url = URL(string: "pocketleak://quick-add") else { return }
                                openURL(url)
                            }
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
                    .opacity(didAnimateIn ? 1 : 0)
                    .offset(y: didAnimateIn ? 0 : 8)

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
