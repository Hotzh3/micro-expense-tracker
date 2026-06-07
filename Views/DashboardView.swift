import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricCardView(title: "Today", value: amount(viewModel.todayTotal), subtitle: "Live in-memory total")
                    MetricCardView(title: "This Week", value: amount(viewModel.weekTotal), subtitle: "Live in-memory total")
                    MetricCardView(title: "This Month", value: amount(viewModel.monthTotal), subtitle: "Live in-memory total")
                    MetricCardView(title: "Top Category", value: viewModel.topCategory?.displayName ?? "—", subtitle: "Live in-memory total")
                }

                GlassCardView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick Snapshot")
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText)
                        Text("Weekly and monthly totals update immediately after you save a micro-expense.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .safeAreaPadding(.bottom, 24)
        }
    }

    private func amount(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}
