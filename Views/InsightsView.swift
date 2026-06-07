import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                MetricCardView(title: "Average Daily Spend", value: currency(viewModel.averageDailySpend), subtitle: "Based on saved expenses")
                MetricCardView(title: "Projected Monthly Spend", value: currency(viewModel.projectedMonthlySpend), subtitle: "Based on saved expenses")
                MetricCardView(title: "Top Category", value: viewModel.topCategory?.displayName ?? "—", subtitle: "Based on saved expenses")
                MetricCardView(title: "Total Expenses", value: "\(viewModel.totalExpenseCount)", subtitle: "In-memory entries")
            }
            .padding(16)
            .safeAreaPadding(.bottom, 24)
        }
    }

    private func currency(_ amount: Double) -> String {
        String(format: "$%.2f", amount)
    }
}
