import SwiftUI

struct InsightsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                MetricCardView(title: "Average Daily Spend", value: "$0.00", subtitle: "Placeholder insight")
                MetricCardView(title: "Projected Monthly Spend", value: "$0.00", subtitle: "Placeholder insight")
                MetricCardView(title: "Top Category", value: "Coffee", subtitle: "Placeholder insight")
                MetricCardView(title: "Week-over-Week Change", value: "0%", subtitle: "Placeholder insight")
            }
            .padding(16)
        }
    }
}
