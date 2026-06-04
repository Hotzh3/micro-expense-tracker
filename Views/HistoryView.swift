import SwiftUI

struct HistoryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                EmptyStateView(
                    title: "No history yet",
                    message: "Saved expenses will appear here once persistence is added."
                )
            }
            .padding(16)
        }
    }
}
