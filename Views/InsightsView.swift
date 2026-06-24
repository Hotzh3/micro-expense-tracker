import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAnimateIn = false

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

                    CalendarReviewView()

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
