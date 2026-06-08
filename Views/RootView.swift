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
    @State private var showLaunchSplash = true
    @State private var didRunSplashTimer = false
    @State private var showSettings = false
    @State private var splashPhrase = LaunchSplashView.randomPhrase()

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
            .environment(\.presentSettings, { showSettings = true })

            if showLaunchSplash {
                LaunchSplashView(phrase: splashPhrase)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            guard !didRunSplashTimer else { return }
            didRunSplashTimer = true
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            withAnimation(.easeInOut(duration: 0.45)) {
                showLaunchSplash = false
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                versionText: "v0.1",
                onOpenHistory: {
                    selectedTab = .history
                },
                onResetLocalData: {
                    viewModel.clearAllExpenses()
                }
            )
        }
        .onOpenURL { url in
            guard let route = PocketLeakRoute(url: url) else { return }

            switch route {
            case .dashboard:
                selectedTab = .dashboard
            case .history:
                selectedTab = .history
            case .insights:
                selectedTab = .insights
            case .quickAdd(let draft):
                selectedTab = .quickAdd
                viewModel.prefillDraft(
                    amount: draft.amount,
                    merchant: draft.merchant,
                    category: draft.category,
                    source: draft.hasPrefill ? .imported : .manual
                )
                viewModel.clearParseFeedback()
            }
        }
    }
}

private enum PocketLeakRoute {
    struct QuickAddDraft {
        let amount: String?
        let merchant: String?
        let category: String?

        var hasPrefill: Bool {
            [amount, merchant, category].contains(where: { value in
                if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return true
                }
                return false
            })
        }
    }

    case quickAdd(QuickAddDraft)
    case dashboard
    case history
    case insights

    init?(url: URL) {
        guard let scheme = url.scheme?.lowercased(), ["jtap", "pocketleak"].contains(scheme) else {
            return nil
        }

        let host = url.host?.lowercased() ?? ""
        let pathRoute = url.pathComponents.dropFirst().first?.lowercased() ?? ""
        let destination = host.isEmpty ? pathRoute : host
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        switch destination {
        case "dashboard":
            self = .dashboard
        case "history":
            self = .history
        case "insights":
            self = .insights
        case "add", "quick-add", "quickadd", "":
            let draft = QuickAddDraft(
                amount: Self.queryValue(named: "amount", in: queryItems),
                merchant: Self.queryValue(named: "merchant", in: queryItems),
                category: Self.queryValue(named: "category", in: queryItems)
            )
            self = .quickAdd(draft)
        default:
            return nil
        }
    }

    private static func queryValue(named name: String, in items: [URLQueryItem]) -> String? {
        items.first(where: { $0.name.lowercased() == name.lowercased() })?.value
    }
}
