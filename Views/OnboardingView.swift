import SwiftUI

struct OnboardingView: View {
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.appTextSize) private var appTextSize: AppTextSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onGetStarted: () -> Void
    let onSkip: () -> Void

    @State private var selectedPage = 0
    @State private var didAnimateIn = false

    private let pages = OnboardingPage.allCases

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(strings.appName)
                            .font(.system(size: 28 * scale, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.primaryText)
                        Text(strings.onboardingDescription)
                            .font(.system(size: 15 * scale))
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer(minLength: 0)

                    Button(strings.onboardingSkip) {
                        onSkip()
                    }
                    .font(.system(size: 14 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppTheme.cardFill)
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(AppTheme.cardBorder, lineWidth: 1)
                            )
                    )
                    .buttonStyle(.plain)
                }

                TabView(selection: $selectedPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageCard(for: page, index: index)
                            .tag(index)
                            .padding(.vertical, 4)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 340 * scale)

                HStack(spacing: 8) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, _ in
                        Capsule(style: .continuous)
                            .fill(index == selectedPage ? AppTheme.primaryText : AppTheme.cardBorder)
                            .frame(width: index == selectedPage ? 22 : 8, height: 8)
                            .animation(AppMotion.animation(reduceMotion: reduceMotion, fallback: AppMotion.quick), value: selectedPage)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 2)

                Button {
                    onGetStarted()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text(strings.onboardingGetStarted)
                    }
                    .font(.system(size: 16 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppTheme.primaryText)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    onSkip()
                } label: {
                    Text(strings.onboardingSkip)
                        .font(.system(size: 15 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .opacity(didAnimateIn ? 1 : 0)
            .offset(y: didAnimateIn ? 0 : 10)
        }
        .onAppear {
            guard !didAnimateIn else { return }
            if reduceMotion {
                didAnimateIn = true
            } else {
                withAnimation(AppMotion.animation(reduceMotion: reduceMotion, fallback: AppMotion.standard)) {
                    didAnimateIn = true
                }
            }
        }
        .animation(AppMotion.animation(reduceMotion: reduceMotion, fallback: AppMotion.standard), value: didAnimateIn)
    }

    private var scale: CGFloat {
        appTextSize.scale
    }

    @ViewBuilder
    private func pageCard(for page: OnboardingPage, index: Int) -> some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(page.title(strings))
                            .font(.system(size: 22 * scale, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.primaryText)
                        Text(page.description(strings))
                            .font(.system(size: 15 * scale))
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer(minLength: 0)

                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(AppTheme.chipFill)
                            .frame(width: 76, height: 76)
                        Image(systemName: page.symbol)
                            .font(.system(size: 30 * scale, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryText)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    onboardingBullet(page.bulletOne(strings))
                    onboardingBullet(page.bulletTwo(strings))
                }
                .padding(.top, 6)

                Spacer(minLength: 0)

                HStack {
                    Text("\(index + 1)/\(pages.count)")
                        .font(.system(size: 12 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.tertiaryText)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private func onboardingBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(AppTheme.primaryText)
                .frame(width: 8, height: 8)
                .padding(.top, 7)

            Text(text)
                .font(.system(size: 14 * scale))
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}

private enum OnboardingPage: CaseIterable {
    case one
    case two
    case three
    case four

    var symbol: String {
        switch self {
        case .one:
            return "bolt.fill"
        case .two:
            return "doc.text.magnifyingglass"
        case .three:
            return "target"
        case .four:
            return "widget.small"
        }
    }

    func title(_ strings: AppStrings) -> String {
        switch self {
        case .one:
            return strings.onboardingPageOneTitle
        case .two:
            return strings.onboardingPageTwoTitle
        case .three:
            return strings.onboardingPageThreeTitle
        case .four:
            return strings.onboardingPageFourTitle
        }
    }

    func description(_ strings: AppStrings) -> String {
        switch self {
        case .one:
            return strings.onboardingPageOneDescription
        case .two:
            return strings.onboardingPageTwoDescription
        case .three:
            return strings.onboardingPageThreeDescription
        case .four:
            return strings.onboardingPageFourDescription
        }
    }

    func bulletOne(_ strings: AppStrings) -> String {
        switch self {
        case .one:
            return strings.onboardingPageOneBulletOne
        case .two:
            return strings.onboardingPageTwoBulletOne
        case .three:
            return strings.onboardingPageThreeBulletOne
        case .four:
            return strings.onboardingPageFourBulletOne
        }
    }

    func bulletTwo(_ strings: AppStrings) -> String {
        switch self {
        case .one:
            return strings.onboardingPageOneBulletTwo
        case .two:
            return strings.onboardingPageTwoBulletTwo
        case .three:
            return strings.onboardingPageThreeBulletTwo
        case .four:
            return strings.onboardingPageFourBulletTwo
        }
    }
}
