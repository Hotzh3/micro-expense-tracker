import SwiftUI

struct RootView: View {
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            TabView {
                QuickAddView()
                    .tabItem {
                        Label("Quick Add", systemImage: "plus.circle.fill")
                    }

                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "square.grid.2x2.fill")
                    }

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }

                InsightsView()
                    .tabItem {
                        Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                    }
            }
            .tint(AppTheme.primaryText)
            .toolbarBackground(AppTheme.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
    }
}
