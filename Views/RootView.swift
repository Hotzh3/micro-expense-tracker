import SwiftUI

struct RootView: View {
    enum AppTab: Hashable {
        case quickAdd
        case dashboard
        case history
        case insights
    }

    @EnvironmentObject private var viewModel: ExpenseViewModel
    @State private var selectedTab: AppTab = .quickAdd

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                QuickAddView()
                    .tag(AppTab.quickAdd)
                    .tabItem {
                        Label("Quick Add", systemImage: "plus.circle.fill")
                    }

                DashboardView()
                    .tag(AppTab.dashboard)
                    .tabItem {
                        Label("Dashboard", systemImage: "square.grid.2x2.fill")
                    }

                HistoryView()
                    .tag(AppTab.history)
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }

                InsightsView()
                    .tag(AppTab.insights)
                    .tabItem {
                        Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                    }
            }
            .tint(AppTheme.primaryText)
            .toolbarBackground(AppTheme.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onOpenURL { url in
            guard url.scheme?.lowercased() == "jtap" else { return }
            selectedTab = .quickAdd

            if let host = url.host?.lowercased(), host == "dashboard" {
                selectedTab = .dashboard
            }

            if let host = url.host?.lowercased(), host == "history" {
                selectedTab = .history
            }

            if let host = url.host?.lowercased(), host == "insights" {
                selectedTab = .insights
            }

            if let host = url.host?.lowercased(), host == "quick-add" {
                viewModel.clearParseFeedback()
            }
        }
    }
}
