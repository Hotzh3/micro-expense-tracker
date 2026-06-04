import SwiftUI

struct RootView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @State private var selectedTab: Tab = .quickAdd

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Picker("Section", selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                Group {
                    switch selectedTab {
                    case .quickAdd:
                        QuickAddView()
                    case .dashboard:
                        DashboardView()
                    case .history:
                        HistoryView()
                    case .insights:
                        InsightsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("J Tap")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.primaryText)
                Text("Capture micro-expenses with minimal friction.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardFill)
                .overlay(
                    Text("J")
                        .font(.headline.bold())
                        .foregroundStyle(AppTheme.primaryText)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
                .frame(width: 52, height: 52)
        }
        .padding(16)
    }
}

private enum Tab: String, CaseIterable, Identifiable {
    case quickAdd
    case dashboard
    case history
    case insights

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quickAdd: return "Quick Add"
        case .dashboard: return "Dashboard"
        case .history: return "History"
        case .insights: return "Insights"
        }
    }
}
