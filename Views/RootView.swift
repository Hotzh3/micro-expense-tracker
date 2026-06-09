import SwiftUI
import UIKit
import Combine

struct RootView: View {
    enum AppTab: Hashable, CaseIterable {
        case quickAdd
        case dashboard
        case goals
        case history
        case insights
    }

    @EnvironmentObject private var viewModel: ExpenseViewModel
    @AppStorage(AppPreferenceKeys.appearance) private var appearanceRaw = AppAppearance.dark.rawValue
    @AppStorage(AppPreferenceKeys.textSize) private var textSizeRaw = AppTextSize.medium.rawValue
    @AppStorage(AppPreferenceKeys.language) private var languageRaw = AppLanguage.english.rawValue
    @Environment(\.appTextSize) private var appTextSize: AppTextSize
    @Environment(\.openURL) private var openURL

    @State private var selectedTab: AppTab = .quickAdd
    @State private var showLaunchSplash = true
    @State private var didRunSplashTimer = false
    @State private var showSettings = false
    @State private var splashPhrase = LaunchSplashView.randomPhrase()
    @State private var isKeyboardVisible = false

    var body: some View {
        let appearance = AppAppearance(rawValue: appearanceRaw) ?? .dark
        let textSize = AppTextSize(rawValue: textSizeRaw) ?? .medium
        let language = AppLanguage(rawValue: languageRaw) ?? .english
        let strings = AppStrings.current()
        let bottomContentInset: CGFloat = isKeyboardVisible ? 24 : 132
        let tabBarBottomPadding: CGFloat = 2
        let tabBarContainerHeight: CGFloat = 104

        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                AppTheme.background.ignoresSafeArea()

                tabContent()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .environment(\.presentSettings, { showSettings = true })
                    .environment(\.appAppearance, appearance)
                    .environment(\.appTextSize, textSize)
                    .environment(\.appLanguage, language)
                    .environment(\.pocketLeakStrings, strings)
                    .environment(\.locale, language.locale)
                    .preferredColorScheme(appearance.colorScheme)
                    .padding(.bottom, bottomContentInset)

                if showLaunchSplash {
                    LaunchSplashView(phrase: splashPhrase)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(20)
                } else if !isKeyboardVisible {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        tabBar(strings: strings)
                            .padding(.horizontal, 18)
                            .padding(.bottom, tabBarBottomPadding)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: proxy.safeAreaInsets.bottom + tabBarContainerHeight, alignment: .bottom)
                    .background(
                        AppTheme.background
                            .ignoresSafeArea(edges: .bottom)
                    )
                    .zIndex(10)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        .task {
            guard !didRunSplashTimer else { return }
            didRunSplashTimer = true
            try? await Task.sleep(nanoseconds: 2_700_000_000)
            withAnimation(.easeInOut(duration: 0.45)) {
                showLaunchSplash = false
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                appearanceSelection: Binding(
                    get: { AppAppearance(rawValue: appearanceRaw) ?? .dark },
                    set: { appearanceRaw = $0.rawValue }
                ),
                textSizeSelection: Binding(
                    get: { AppTextSize(rawValue: textSizeRaw) ?? .medium },
                    set: { textSizeRaw = $0.rawValue }
                ),
                languageSelection: Binding(
                    get: { AppLanguage(rawValue: languageRaw) ?? .english },
                    set: { languageRaw = $0.rawValue }
                ),
                versionText: "v0.1",
                onOpenHistory: {
                    selectedTab = .history
                },
                onOpenGoals: {
                    selectedTab = .goals
                },
                onOpenQuickAdd: {
                    selectedTab = .quickAdd
                },
                onCopyQuickAddURL: {
                    UIPasteboard.general.string = "pocketleak://quick-add"
                },
                onCopyPrefillURLExample: {
                    UIPasteboard.general.string = "pocketleak://add?amount=120&merchant=Oxxo&category=food"
                },
                onOpenQuickAddRoute: {
                    guard let url = URL(string: "pocketleak://quick-add") else { return }
                    openURL(url)
                },
                onResetLocalData: {
                    viewModel.clearAllData()
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
            case .goals:
                selectedTab = .goals
            case .quickAdd(let draft):
                selectedTab = .quickAdd
                viewModel.resetDraftForExternalEntry()
                viewModel.prefillDraft(
                    amount: draft.amount,
                    merchant: draft.merchant,
                    category: draft.category,
                    source: draft.hasPrefill ? .imported : .manual
                )
                viewModel.clearParseFeedback()
            case .parseText(let text):
                selectedTab = .quickAdd
                viewModel.loadImportedTextAndParse(text)
            }
        }
    }

    @ViewBuilder
    private func tabContent() -> some View {
        switch selectedTab {
        case .quickAdd:
            QuickAddView()
        case .dashboard:
            DashboardView()
        case .goals:
            GoalsView()
        case .history:
            HistoryView()
        case .insights:
            InsightsView()
        }
    }

    private func tabBar(strings: AppStrings) -> some View {
        let scale = appTextSize.scale
        return VStack(spacing: 0) {
            Divider()
                .overlay(AppTheme.cardBorder)

            HStack(spacing: 2) {
                tabButton(title: strings.quickAddTab, systemImage: "plus.circle.fill", tab: .quickAdd)
                tabButton(title: strings.dashboardTab, systemImage: "square.grid.2x2.fill", tab: .dashboard)
                tabButton(title: strings.goalsTab, systemImage: "target", tab: .goals)
                tabButton(title: strings.historyTab, systemImage: "clock.arrow.circlepath", tab: .history)
                tabButton(title: strings.insightsTab, systemImage: "chart.line.uptrend.xyaxis", tab: .insights)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 16)
            .background(AppTheme.background)
        }
        .frame(height: 92 * scale)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    )
            )
        .shadow(color: .black.opacity(0.28), radius: 20, x: 0, y: 12)
    }

    private func tabButton(title: String, systemImage: String, tab: AppTab) -> some View {
        let scale = appTextSize.scale
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 21 * scale, weight: .semibold))
                Text(title)
                    .font(.system(size: 12 * scale, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(selectedTab == tab ? AppTheme.primaryText : AppTheme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 2)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selectedTab == tab ? AppTheme.cardFill : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selectedTab == tab ? AppTheme.cardBorder : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .frame(minHeight: 68 * scale)
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
    case goals
    case parseText(String)

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
        case "goals":
            self = .goals
        case "parse":
            let text = Self.queryValue(named: "text", in: queryItems) ?? ""
            self = .parseText(text)
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
