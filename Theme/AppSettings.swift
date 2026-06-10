import SwiftUI

enum AppPreferenceKeys {
    static let appearance = "app.appearance"
    static let textSize = "app.textSize"
    static let language = "app.language"
    static let hapticsEnabled = "app.hapticsEnabled"
    static let smartAlertsEnabled = "app.smartAlertsEnabled"
    static let dismissedSmartAlertIDs = "app.dismissedSmartAlertIDs"
    static let hasSeenOnboarding = "app.hasSeenOnboarding"
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case dark
    case light

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }
}

enum AppTextSize: String, CaseIterable, Identifiable {
    case xs
    case small
    case medium
    case large
    case xl

    var id: String { rawValue }

    var scale: CGFloat {
        switch self {
        case .xs:
            return 0.9
        case .small:
            return 1.02
        case .medium:
            return 1.16
        case .large:
            return 1.3
        case .xl:
            return 1.48
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english
    case spanish

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .english:
            return Locale(identifier: "en")
        case .spanish:
            return Locale(identifier: "es")
        }
    }
}

struct AppStrings {
    let appName: String
    let quickAddTab: String
    let dashboardTab: String
    let historyTab: String
    let insightsTab: String
    let goalsTab: String
    let quickAddHeader: String
    let dashboardHeader: String
    let dashboardHeaderSubtitle: String
    let historyHeader: String
    let insightsHeader: String
    let goalsHeader: String
    let goalsHeaderSubtitle: String
    let settingsTitle: String
    let settingsDescription: String
    let onboardingTitle: String
    let onboardingDescription: String
    let showOnboardingAgain: String
    let onboardingGetStarted: String
    let onboardingSkip: String
    let onboardingPageOneTitle: String
    let onboardingPageOneDescription: String
    let onboardingPageOneBulletOne: String
    let onboardingPageOneBulletTwo: String
    let onboardingPageTwoTitle: String
    let onboardingPageTwoDescription: String
    let onboardingPageTwoBulletOne: String
    let onboardingPageTwoBulletTwo: String
    let onboardingPageThreeTitle: String
    let onboardingPageThreeDescription: String
    let onboardingPageThreeBulletOne: String
    let onboardingPageThreeBulletTwo: String
    let onboardingPageFourTitle: String
    let onboardingPageFourDescription: String
    let onboardingPageFourBulletOne: String
    let onboardingPageFourBulletTwo: String
    let appearanceTitle: String
    let appearanceDescription: String
    let textSizeTitle: String
    let textSizeDescription: String
    let languageTitle: String
    let languageDescription: String
    let hapticsTitle: String
    let hapticsDescription: String
    let enableHaptics: String
    let privacyTitle: String
    let privacyNote: String
    let dataTitle: String
    let exportData: String
    let exportDescription: String
    let aboutTitle: String
    let aboutDescription: String
    let versionLabel: String
    let resetTitle: String
    let resetButton: String
    let resetConfirmationTitle: String
    let resetConfirmationMessage: String
    let deleteAllData: String
    let cancel: String
    let backTapTitle: String
    let backTapDescription: String
    let copyQuickAddURL: String
    let copyPrefillURLExample: String
    let openQuickAddRoute: String
    let openQuickAdd: String
    let openHistoryExports: String
    let openGoals: String
    let openHistory: String
    let openSettings: String
    let accessibilitySelected: String
    let accessibilityNotSelected: String
    let openSettingsHint: String
    let deleteExpenseHint: String
    let categoryTapHint: String
    let switchTabHint: String
    let deleteExpenseAccessibilityLabel: String
    let appearance: String
    let textSize: String
    let language: String
    let resetLocalData: String
    let backTapQuickAdd: String
    let backTapStepOpenShortcuts: String
    let backTapStepCreateShortcut: String
    let backTapStepAddOpenURLs: String
    let backTapStepUseQuickAddURL: String
    let backTapStepOpenAccessibility: String
    let backTapStepSelectShortcut: String
    let emptyNoExpenses: String
    let emptyNoInsights: String
    let emptyNoGoals: String
    let dashboardEmptyStateTitle: String
    let dashboardEmptyStateMessage: String
    let dashboardEmptyStateAction: String
    let insightsEmptyStateTitle: String
    let insightsEmptyStateMessage: String
    let insightsEmptyStateAction: String
    let historyEmptyStateTitle: String
    let historyEmptyStateMessage: String
    let historyEmptyStateAction: String
    let historyNoResultsTitle: String
    let historyNoResultsMessage: String
    let historyNoResultsAction: String
    let done: String
    let amountTitle: String
    let amountPlaceholder: String
    let quickAddIntro: String
    let next: String
    let categoryTitle: String
    let categorySubtitle: String
    let detailsTitle: String
    let merchantPlaceholder: String
    let notePlaceholder: String
    let pasteTitle: String
    let pasteDescription: String
    let pasteFromClipboard: String
    let clipboardEmptyMessage: String
    let parseTextButton: String
    let useParsedExpenseButton: String
    let saveExpenseButton: String
    let expenseSaved: String
    let saveMissingAmountError: String
    let parseNoResultMessage: String
    let parsedPreviewTitle: String
    let parsedPreviewSubtitle: String
    let rawMerchantLabel: String
    let normalizedMerchantLabel: String
    let merchantLabel: String
    let confidenceLabel: String
    let sourceLabel: String
    let parsedTextSource: String
    let ready: String
    let needsAttention: String
    let missingAmountParseError: String
    let dashboardQuickSnapshotTitle: String
    let dashboardCategoryDistributionTitle: String
    let dashboardRecentTrendTitle: String
    let dashboardSignalTitle: String
    let dashboardSignalSubtitle: String
    let dashboardGoalsTitle: String
    let dashboardGoalsSubtitle: String
    let dashboardGoalsCtaTitle: String
    let dashboardGoalsCtaSubtitle: String
    let dashboardGoalsCtaButton: String
    let dashboardNoCategoryDistribution: String
    let dashboardNoRecentTrend: String
    let historyExportsTitle: String
    let historyFilterTitle: String
    let historyCategoryTitle: String
    let historyResetFilters: String
    let historyNoMatchingExpenses: String
    let exportCSV: String
    let exportJSON: String
    let exportMonthlySummary: String
    let shareSummaryButton: String
    let shareSummaryWeeklyCardTitle: String
    let shareSummaryMonthlyCardTitle: String
    let shareSummaryGoalCardTitle: String
    let shareSummaryTopCategoryCardTitle: String
    let shareSummaryBadgeWeekly: String
    let shareSummaryBadgeMonthly: String
    let shareSummaryBadgeGoal: String
    let shareSummaryBadgeTopCategory: String
    let shareSummaryTopCategoryChipPrefix: String
    let shareSummaryTopCategoryShareTemplate: String
    let shareSummaryTopCategoryCountTemplate: String
    let shareSummaryWeeklyMessage: String
    let shareSummaryMonthlyMessage: String
    let shareSummaryGoalMessage: String
    let shareSummaryTopCategoryMessage: String
    let insightsWeeklyTotalsTitle: String
    let insightsCategoryBreakdownTitle: String
    let insightsNoCategoryBreakdown: String
    let trendsTitle: String
    let trendsSubtitle: String
    let trendTodayVsYesterdayTitle: String
    let trendWeekVsLastWeekTitle: String
    let trendMonthVsLastMonthTitle: String
    let trendDailyAverageWeekTitle: String
    let trendTopCategoryComparisonTitleTemplate: String
    let trendCurrentLabel: String
    let trendPreviousLabel: String
    let trendNoPreviousDataMessage: String
    let trendHigherMessageTemplate: String
    let trendLowerMessageTemplate: String
    let trendFlatMessage: String
    let weeklyDigestTitle: String
    let weeklyDigestSubtitle: String
    let weeklyDigestEmptyTitle: String
    let weeklyDigestEmptyMessage: String
    let weeklyDigestEmptyAction: String
    let weeklyDigestDateRangeTemplate: String
    let weeklyDigestExpenseCountTemplate: String
    let weeklyDigestTopCategoryLabel: String
    let weeklyDigestAverageDailyLabel: String
    let weeklyDigestLargestExpenseLabel: String
    let weeklyDigestGoalStatusLabel: String
    let weeklyDigestBestInsightLabel: String
    let weeklyDigestComparisonLabel: String
    let weeklyDigestNoComparisonMessage: String
    let weeklyDigestShareButton: String
    let smartAlertsTitle: String
    let smartAlertsSubtitle: String
    let smartAlertsDescription: String
    let enableSmartAlerts: String
    let smartAlertsDismiss: String
    let smartAlertsNoDataTitle: String
    let smartAlertsNoDataMessage: String
    let smartAlertsGoalRiskTitle: String
    let smartAlertsGoalWatchWeeklyMessageTemplate: String
    let smartAlertsGoalWatchMonthlyMessageTemplate: String
    let smartAlertsGoalRiskWeeklyMessageTemplate: String
    let smartAlertsGoalRiskMonthlyMessageTemplate: String
    let smartAlertsGoalOverWeeklyMessageTemplate: String
    let smartAlertsGoalOverMonthlyMessageTemplate: String
    let smartAlertsTodayAboveAverageTitle: String
    let smartAlertsTodayAboveAverageMessageTemplate: String
    let smartAlertsCategorySpikeTitle: String
    let smartAlertsCategorySpikeMessageTemplate: String
    let smartAlertsPositiveTrendTitle: String
    let smartAlertsPositiveTrendMessageTemplate: String
    let smartInsightsTitle: String
    let smartInsightsSubtitle: String
    let smartInsightsNoDataTitle: String
    let smartInsightsNoDataMessage: String
    let smartInsightsTopCategoryWeekTitle: String
    let smartInsightsTopCategoryMonthTitle: String
    let smartInsightsTopCategoryWeekMessage: String
    let smartInsightsTopCategoryMonthMessage: String
    let smartInsightsDailyAverageWeekTitle: String
    let smartInsightsDailyAverageMonthTitle: String
    let smartInsightsDailyAverageWeekMessage: String
    let smartInsightsDailyAverageMonthMessage: String
    let smartInsightsSpendingIncreaseTitle: String
    let smartInsightsSpendingDecreaseTitle: String
    let smartInsightsSpendingIncreaseMessage: String
    let smartInsightsSpendingDecreaseMessage: String
    let smartInsightsGoalRiskTitle: String
    let smartInsightsPositiveTrendTitle: String
    let smartInsightsNeutralTitle: String
    let smartInsightsGoalRiskWeeklyLimitReachedMessage: String
    let smartInsightsGoalRiskMonthlyLimitReachedMessage: String
    let smartInsightsGoalRiskWeeklyCloseToLimitMessage: String
    let smartInsightsGoalRiskMonthlyCloseToLimitMessage: String
    let goalsWeeklyTitle: String
    let goalsMonthlyTitle: String
    let goalsCreateWeekly: String
    let goalsCreateMonthly: String
    let goalsEdit: String
    let goalsRemove: String
    let goalsLimitLabel: String
    let goalsSpentLabel: String
    let goalsRemainingLabel: String
    let goalsPercentUsedLabel: String
    let goalsDaysLeftLabel: String
    let goalsRemainingDailyBudgetLabel: String
    let goalsProjectedMonthSpendLabel: String
    let goalsStatusOnTrack: String
    let goalsStatusCloseToLimit: String
    let goalsStatusLimitReached: String
    let goalsNoGoalStatus: String
    let goalsNoGoalMessage: String
    let goalsPeriodThisWeek: String
    let goalsPeriodThisMonth: String
    let goalsWeeklyOnTrackMessageTemplate: String
    let goalsWeeklyCloseToLimitMessage: String
    let goalsWeeklyLimitReachedMessage: String
    let goalsMonthlyOnTrackMessageTemplate: String
    let goalsMonthlyCloseToLimitMessage: String
    let goalsMonthlyLimitReachedMessage: String
    let goalsEmptyWeekly: String
    let goalsEmptyMonthly: String
    let goalsEditorTitle: String
    let goalsGoalLogicDescription: String
    let goalsForecastTitle: String
    let goalsForecastAtThisPaceTemplate: String
    let goalsForecastDailyBudgetTemplate: String
    let goalsForecastStayUnderTemplate: String
    let goalsForecastGoOverTemplate: String
    let goalsForecastOverSummary: String
    let goalForecastStatusSafe: String
    let goalForecastStatusWatch: String
    let goalForecastStatusRisk: String
    let goalForecastStatusOver: String
    let dashboardGoalAtRiskTitleTemplate: String
    let dashboardGoalAtRiskSubtitleTemplate: String
    let goalsRemoveConfirmationTitle: String
    let goalsRemoveConfirmationMessage: String

    static func current() -> AppStrings {
        let language = AppLanguage.current
        switch language {
        case .english:
            return AppStrings(
                appName: "Pocket Leak",
                quickAddTab: "Quick Add",
                dashboardTab: "Dashboard",
                historyTab: "History",
                insightsTab: "Insights",
                goalsTab: "Goals",
                quickAddHeader: "Quick Add",
                dashboardHeader: "Dashboard",
                dashboardHeaderSubtitle: "Track daily spend, month totals, and the categories leaking the most.",
                historyHeader: "History",
                insightsHeader: "Insights",
                goalsHeader: "Goals",
                goalsHeaderSubtitle: "Track weekly and monthly limits side by side so the pace stays visible.",
                settingsTitle: "Settings",
                settingsDescription: "Minimal local-first expense capture with parsing, exports, and goal tracking.",
                onboardingTitle: "Onboarding",
                onboardingDescription: "Replay the first-launch guide whenever you want a quick refresher.",
                showOnboardingAgain: "Show Onboarding Again",
                onboardingGetStarted: "Get Started",
                onboardingSkip: "Skip",
                onboardingPageOneTitle: "Track micro-expenses fast",
                onboardingPageOneDescription: "Capture small spend as it happens, so nothing gets forgotten later.",
                onboardingPageOneBulletOne: "Log expenses before the moment passes.",
                onboardingPageOneBulletTwo: "Quick Add stays local and lightweight.",
                onboardingPageTwoTitle: "Paste transaction text safely",
                onboardingPageTwoDescription: "Paste alerts or receipts manually. Pocket Leak parses only the text you choose.",
                onboardingPageTwoBulletOne: "Paste text only when you choose to.",
                onboardingPageTwoBulletTwo: "The parser never reads notifications automatically.",
                onboardingPageThreeTitle: "Set weekly and monthly goals",
                onboardingPageThreeDescription: "Keep both budget rhythms visible and know when you are close to the limit.",
                onboardingPageThreeBulletOne: "See weekly and monthly pace at once.",
                onboardingPageThreeBulletTwo: "Track remaining budget before overspending.",
                onboardingPageFourTitle: "Add widgets and Back Tap",
                onboardingPageFourDescription: "Surface daily spend on your Home Screen and trigger Quick Add with a shortcut.",
                onboardingPageFourBulletOne: "Widgets keep today visible at a glance.",
                onboardingPageFourBulletTwo: "Back Tap can open Quick Add through Shortcuts.",
                appearanceTitle: "Appearance",
                appearanceDescription: "System follows device appearance. Dark keeps the premium black shell. Light flips the palette for contrast testing.",
                textSizeTitle: "Text Size",
                textSizeDescription: "This scales headers, subtitles, cards, buttons, tab labels, and input fields across the app.",
                languageTitle: "Language",
                languageDescription: "Language updates the main tabs, headers, empty states, settings, and Back Tap instructions.",
                hapticsTitle: "Haptics",
                hapticsDescription: "Subtle feedback for taps, saves, parser errors, and tab changes.",
                enableHaptics: "Enable Haptics",
                privacyTitle: "Privacy",
                privacyNote: "Pocket Leak stores expenses locally and only parses text you paste manually.",
                dataTitle: "Data",
                exportData: "Export Data",
                exportDescription: "Open History to share CSV, JSON, or the monthly summary report.",
                aboutTitle: "About",
                aboutDescription: "Built for fast, local-first capture.",
                versionLabel: "Version",
                resetTitle: "Reset",
                resetButton: "Reset Local Data",
                resetConfirmationTitle: "Reset local data?",
                resetConfirmationMessage: "This deletes local expenses and goals on this device. It cannot be undone.",
                deleteAllData: "Delete All Data",
                cancel: "Cancel",
                backTapTitle: "Back Tap Quick Add",
                backTapDescription: "iOS cannot let Pocket Leak detect Back Tap directly. Build a Shortcut with Open URLs, point it at pocketleak://quick-add, then assign that Shortcut to Back Tap.",
                copyQuickAddURL: "Copy pocketleak://quick-add",
                copyPrefillURLExample: "Copy Prefill URL Example",
                openQuickAddRoute: "Open Quick Add Route",
                openQuickAdd: "Open Quick Add",
                openHistoryExports: "Open History Exports",
                openGoals: "Open Goals",
                openHistory: "Open History",
                openSettings: "Open Settings",
                accessibilitySelected: "Selected",
                accessibilityNotSelected: "Not selected",
                openSettingsHint: "Open the settings screen.",
                deleteExpenseHint: "Deletes this saved expense.",
                categoryTapHint: "Tap to select this category.",
                switchTabHint: "Switches to this tab.",
                deleteExpenseAccessibilityLabel: "Delete expense",
                appearance: "Appearance",
                textSize: "Text Size",
                language: "Language",
                resetLocalData: "Reset Local Data",
                backTapQuickAdd: "Back Tap Quick Add",
                backTapStepOpenShortcuts: "1. Open the Shortcuts app.",
                backTapStepCreateShortcut: "2. Create a new shortcut.",
                backTapStepAddOpenURLs: "3. Add the Open URLs action.",
                backTapStepUseQuickAddURL: "4. Set the URL to pocketleak://quick-add.",
                backTapStepOpenAccessibility: "5. Go to Settings > Accessibility > Touch > Back Tap.",
                backTapStepSelectShortcut: "6. Choose Double Tap and select your shortcut.",
                emptyNoExpenses: "No expenses yet.",
                emptyNoInsights: "No insights yet.",
                emptyNoGoals: "No goals yet.",
                dashboardEmptyStateTitle: "No expenses yet",
                dashboardEmptyStateMessage: "Add your first expense to unlock trends, goals, and widgets.",
                dashboardEmptyStateAction: "Add First Expense",
                insightsEmptyStateTitle: "No insights yet",
                insightsEmptyStateMessage: "Add a few expenses and Pocket Leak will surface patterns here.",
                insightsEmptyStateAction: "Add First Expense",
                historyEmptyStateTitle: "No history yet",
                historyEmptyStateMessage: "Start with your first saved expense. Everything stays local.",
                historyEmptyStateAction: "Add First Expense",
                historyNoResultsTitle: "No matches",
                historyNoResultsMessage: "Try another filter or reset it.",
                historyNoResultsAction: "Reset Filters",
                done: "Done",
                amountTitle: "Amount",
                amountPlaceholder: "0.00",
                quickAddIntro: "Capture a micro-expense in under 10 seconds.",
                next: "Next",
                categoryTitle: "Category",
                categorySubtitle: "Pick the closest match first. You can always adjust it later.",
                detailsTitle: "Details",
                merchantPlaceholder: "Optional merchant",
                notePlaceholder: "Optional note",
                pasteTitle: "Paste Notification Text",
                pasteDescription: "Paste a bank alert or transaction message. Pocket Leak only parses text you paste yourself, keeping the flow privacy-safe.",
                pasteFromClipboard: "Paste from Clipboard",
                clipboardEmptyMessage: "Clipboard empty. Copy a transaction first.",
                parseTextButton: "Parse Text",
                useParsedExpenseButton: "Use Parsed Expense",
                saveExpenseButton: "Save Expense",
                expenseSaved: "Expense saved",
                saveMissingAmountError: "Enter an amount first.",
                parseNoResultMessage: "No useful text found. Paste a transaction and try again.",
                parsedPreviewTitle: "Parsed Preview",
                parsedPreviewSubtitle: "Review the extracted details before saving.",
                rawMerchantLabel: "Raw merchant",
                normalizedMerchantLabel: "Normalized merchant",
                merchantLabel: "Merchant",
                confidenceLabel: "Confidence",
                sourceLabel: "Source",
                parsedTextSource: "Parsed text",
                ready: "Ready",
                needsAttention: "Needs attention",
                missingAmountParseError: "No amount found. Paste the charge total and try again.",
                dashboardQuickSnapshotTitle: "Quick Snapshot",
                dashboardCategoryDistributionTitle: "Category Distribution",
                dashboardRecentTrendTitle: "Recent Spending Trend",
                dashboardSignalTitle: "Today’s signal",
                dashboardSignalSubtitle: "A short, local read on your spending pattern.",
                dashboardGoalsTitle: "Goals snapshot",
                dashboardGoalsSubtitle: "Keep both budget cadences visible without leaving the dashboard.",
                dashboardGoalsCtaTitle: "Add a goal",
                dashboardGoalsCtaSubtitle: "Create a weekly or monthly limit to see your remaining budget here.",
                dashboardGoalsCtaButton: "Go to Goals",
                dashboardNoCategoryDistribution: "Add a few expenses to see category share.",
                dashboardNoRecentTrend: "Add expenses to see the last 14 days.",
                historyExportsTitle: "Exports",
                historyFilterTitle: "History",
                historyCategoryTitle: "Category",
                historyResetFilters: "Reset",
                historyNoMatchingExpenses: "Try a different category or time filter.",
                exportCSV: "Export CSV",
                exportJSON: "Export JSON",
                exportMonthlySummary: "Share Monthly Summary",
                shareSummaryButton: "Share Summary",
                shareSummaryWeeklyCardTitle: "Weekly Summary",
                shareSummaryMonthlyCardTitle: "Monthly Summary",
                shareSummaryGoalCardTitle: "Goal Progress",
                shareSummaryTopCategoryCardTitle: "Top Category",
                shareSummaryBadgeWeekly: "Weekly",
                shareSummaryBadgeMonthly: "Monthly",
                shareSummaryBadgeGoal: "Goal",
                shareSummaryBadgeTopCategory: "Top",
                shareSummaryTopCategoryChipPrefix: "Top",
                shareSummaryTopCategoryShareTemplate: "%@ of total",
                shareSummaryTopCategoryCountTemplate: "%d expenses",
                shareSummaryWeeklyMessage: "A quick look at your week.",
                shareSummaryMonthlyMessage: "A quick look at your month.",
                shareSummaryGoalMessage: "Your goal progress at a glance.",
                shareSummaryTopCategoryMessage: "Your biggest leak this month.",
                insightsWeeklyTotalsTitle: "Weekly Totals",
                insightsCategoryBreakdownTitle: "Category Breakdown",
                insightsNoCategoryBreakdown: "No breakdown yet.",
                trendsTitle: "Trends",
                trendsSubtitle: "Clear local comparisons across recent periods.",
                trendTodayVsYesterdayTitle: "Today vs Yesterday",
                trendWeekVsLastWeekTitle: "This Week vs Last Week",
                trendMonthVsLastMonthTitle: "This Month vs Last Month",
                trendDailyAverageWeekTitle: "Daily Average This Week",
                trendTopCategoryComparisonTitleTemplate: "%@ vs %@",
                trendCurrentLabel: "Current",
                trendPreviousLabel: "Previous",
                trendNoPreviousDataMessage: "No previous data yet.",
                trendHigherMessageTemplate: "%@ higher than last period",
                trendLowerMessageTemplate: "%@ lower than last period",
                trendFlatMessage: "About the same as the previous period.",
                weeklyDigestTitle: "Weekly Digest",
                weeklyDigestSubtitle: "A quick summary of how the week is going.",
                weeklyDigestEmptyTitle: "Weekly digest will appear here",
                weeklyDigestEmptyMessage: "Add a few expenses during the week and Pocket Leak will build a clear digest automatically.",
                weeklyDigestEmptyAction: "Add First Expense",
                weeklyDigestDateRangeTemplate: "%@ - %@",
                weeklyDigestExpenseCountTemplate: "%d expenses this week",
                weeklyDigestTopCategoryLabel: "Top category",
                weeklyDigestAverageDailyLabel: "Average daily",
                weeklyDigestLargestExpenseLabel: "Largest expense",
                weeklyDigestGoalStatusLabel: "Goal status",
                weeklyDigestBestInsightLabel: "Best insight",
                weeklyDigestComparisonLabel: "Compared with last week",
                weeklyDigestNoComparisonMessage: "No week-over-week comparison yet.",
                weeklyDigestShareButton: "Share digest",
                smartAlertsTitle: "Smart Alerts",
                smartAlertsSubtitle: "Live alerts based on your local spending patterns.",
                smartAlertsDescription: "Shows in-app alerts for risk, spikes, and positive trends.",
                enableSmartAlerts: "Enable Smart Alerts",
                smartAlertsDismiss: "Dismiss",
                smartAlertsNoDataTitle: "No spending yet",
                smartAlertsNoDataMessage: "Add your first expense and Pocket Leak will start surfacing alerts here.",
                smartAlertsGoalRiskTitle: "Goal at risk",
                smartAlertsGoalWatchWeeklyMessageTemplate: "%@ is close to the limit. You have %@/day left.",
                smartAlertsGoalWatchMonthlyMessageTemplate: "%@ is close to the limit. You have %@/day left.",
                smartAlertsGoalRiskWeeklyMessageTemplate: "%@ is in danger of going over by %@.",
                smartAlertsGoalRiskMonthlyMessageTemplate: "%@ is in danger of going over by %@.",
                smartAlertsGoalOverWeeklyMessageTemplate: "%@ is already over by %@.",
                smartAlertsGoalOverMonthlyMessageTemplate: "%@ is already over by %@.",
                smartAlertsTodayAboveAverageTitle: "Today is running hot",
                smartAlertsTodayAboveAverageMessageTemplate: "Today's spend is %@ above your daily average (%@).",
                smartAlertsCategorySpikeTitle: "Category spike",
                smartAlertsCategorySpikeMessageTemplate: "%@ is up %@ vs last week (%@).",
                smartAlertsPositiveTrendTitle: "Positive trend",
                smartAlertsPositiveTrendMessageTemplate: "You spent %@ less than last week (%@).",
                smartInsightsTitle: "Smart Insights",
                smartInsightsSubtitle: "Local patterns from your saved expenses.",
                smartInsightsNoDataTitle: "No insights yet",
                smartInsightsNoDataMessage: "Add a few expenses and Pocket Leak will start surfacing patterns here.",
                smartInsightsTopCategoryWeekTitle: "Top category this week",
                smartInsightsTopCategoryMonthTitle: "Top category this month",
                smartInsightsTopCategoryWeekMessage: "%@ is %@ of your tracked leaks this week.",
                smartInsightsTopCategoryMonthMessage: "%@ is %@ of your tracked leaks this month.",
                smartInsightsDailyAverageWeekTitle: "Daily average this week",
                smartInsightsDailyAverageMonthTitle: "Daily average this month",
                smartInsightsDailyAverageWeekMessage: "You are averaging %@ per day this week.",
                smartInsightsDailyAverageMonthMessage: "You are averaging %@ per day this month.",
                smartInsightsSpendingIncreaseTitle: "Spending is up",
                smartInsightsSpendingDecreaseTitle: "Spending is down",
                smartInsightsSpendingIncreaseMessage: "You spent %@ more than last week (%@).",
                smartInsightsSpendingDecreaseMessage: "You spent %@ less than last week (%@).",
                smartInsightsGoalRiskTitle: "Goal at risk",
                smartInsightsPositiveTrendTitle: "On track",
                smartInsightsNeutralTitle: "Neutral",
                smartInsightsGoalRiskWeeklyLimitReachedMessage: "You are %@ over your weekly limit.",
                smartInsightsGoalRiskMonthlyLimitReachedMessage: "You are %@ over your monthly limit.",
                smartInsightsGoalRiskWeeklyCloseToLimitMessage: "You have %@ left this week.",
                smartInsightsGoalRiskMonthlyCloseToLimitMessage: "You have %@ left this month.",
                goalsWeeklyTitle: "Weekly Goal",
                goalsMonthlyTitle: "Monthly Goal",
                goalsCreateWeekly: "Create Weekly Goal",
                goalsCreateMonthly: "Create Monthly Goal",
                goalsEdit: "Edit",
                goalsRemove: "Remove",
                goalsLimitLabel: "Limit",
                goalsSpentLabel: "Spent",
                goalsRemainingLabel: "Remaining",
                goalsPercentUsedLabel: "% Used",
                goalsDaysLeftLabel: "Days Left",
                goalsRemainingDailyBudgetLabel: "Remaining per day",
                goalsProjectedMonthSpendLabel: "Projected month spend",
                goalsStatusOnTrack: "On track",
                goalsStatusCloseToLimit: "Close to limit",
                goalsStatusLimitReached: "Limit reached",
                goalsNoGoalStatus: "No goal",
                goalsNoGoalMessage: "Create a weekly or monthly spending limit to track progress locally.",
                goalsPeriodThisWeek: "this week",
                goalsPeriodThisMonth: "this month",
                goalsWeeklyOnTrackMessageTemplate: "You have %@ per day left this week.",
                goalsWeeklyCloseToLimitMessage: "You are getting close. Keep the rest of the week intentional.",
                goalsWeeklyLimitReachedMessage: "Weekly spending has reached the limit. Pause before the next cycle.",
                goalsMonthlyOnTrackMessageTemplate: "You have %@ per day left this month. At this pace, you would spend %@ this month.",
                goalsMonthlyCloseToLimitMessage: "You are in the caution zone. Watch the remaining budget carefully.",
                goalsMonthlyLimitReachedMessage: "This month has reached the limit. Keep the next spend intentional.",
                goalsEmptyWeekly: "No weekly goal yet.",
                goalsEmptyMonthly: "No monthly goal yet.",
                goalsEditorTitle: "Goal Editor",
                goalsGoalLogicDescription: "Stay under your selected limit by week or by month.",
                goalsForecastTitle: "Forecast",
                goalsForecastAtThisPaceTemplate: "At this pace, you'll end at %@.",
                goalsForecastDailyBudgetTemplate: "You have %@/day left.",
                goalsForecastStayUnderTemplate: "You are projected to stay under by %@.",
                goalsForecastGoOverTemplate: "You are projected to go over by %@.",
                goalsForecastOverSummary: "You are already over by %@.",
                goalForecastStatusSafe: "Safe",
                goalForecastStatusWatch: "Watch",
                goalForecastStatusRisk: "Risk",
                goalForecastStatusOver: "Over",
                dashboardGoalAtRiskTitleTemplate: "%@ at risk",
                dashboardGoalAtRiskSubtitleTemplate: "You have %@/day left.",
                goalsRemoveConfirmationTitle: "Remove spending goal?",
                goalsRemoveConfirmationMessage: "This removes the local goal from this device."
            )
        case .spanish:
            return AppStrings(
                appName: "Pocket Leak",
                quickAddTab: "Captura",
                dashboardTab: "Panel",
                historyTab: "Historial",
                insightsTab: "Análisis",
                goalsTab: "Metas",
                quickAddHeader: "Captura rápida",
                dashboardHeader: "Panel",
                dashboardHeaderSubtitle: "Sigue el gasto diario, totales mensuales y las categorías que más fugan.",
                historyHeader: "Historial",
                insightsHeader: "Análisis",
                goalsHeader: "Metas",
                goalsHeaderSubtitle: "Sigue límites semanales y mensuales al mismo tiempo para ver el ritmo.",
                settingsTitle: "Ajustes",
                settingsDescription: "Captura de gastos minimalista y local con análisis, exportaciones y metas.",
                onboardingTitle: "Introducción",
                onboardingDescription: "Repite la guía de la primera apertura cuando quieras un repaso rápido.",
                showOnboardingAgain: "Mostrar onboarding de nuevo",
                onboardingGetStarted: "Empezar",
                onboardingSkip: "Omitir",
                onboardingPageOneTitle: "Registra microgastos rápido",
                onboardingPageOneDescription: "Captura gasto pequeño en el momento para que nada se pierda después.",
                onboardingPageOneBulletOne: "Registra gastos antes de que se te pasen.",
                onboardingPageOneBulletTwo: "Quick Add sigue siendo local y ligero.",
                onboardingPageTwoTitle: "Pega texto de transacción con seguridad",
                onboardingPageTwoDescription: "Pega alertas o recibos manualmente. Pocket Leak solo analiza el texto que eliges.",
                onboardingPageTwoBulletOne: "Pega texto solo cuando tú lo decidas.",
                onboardingPageTwoBulletTwo: "El parser nunca lee notificaciones automáticamente.",
                onboardingPageThreeTitle: "Define metas semanales y mensuales",
                onboardingPageThreeDescription: "Mantén visibles ambos ritmos de presupuesto y sabrás cuándo te acercas al límite.",
                onboardingPageThreeBulletOne: "Ve el ritmo semanal y mensual al mismo tiempo.",
                onboardingPageThreeBulletTwo: "Sigue el presupuesto restante antes de gastar de más.",
                onboardingPageFourTitle: "Agrega widgets y Back Tap",
                onboardingPageFourDescription: "Muestra el gasto diario en tu pantalla de inicio y abre Quick Add con un shortcut.",
                onboardingPageFourBulletOne: "Los widgets muestran el día de un vistazo.",
                onboardingPageFourBulletTwo: "Back Tap puede abrir Quick Add con Shortcuts.",
                appearanceTitle: "Apariencia",
                appearanceDescription: "Sistema sigue la apariencia del dispositivo. Oscuro mantiene la shell negra premium. Claro cambia la paleta para pruebas.",
                textSizeTitle: "Tamaño de texto",
                textSizeDescription: "Esto escala encabezados, subtítulos, tarjetas, botones, tabs y campos de entrada en toda la app.",
                languageTitle: "Idioma",
                languageDescription: "El idioma actualiza las tabs principales, encabezados, estados vacíos, ajustes e instrucciones de Back Tap.",
                hapticsTitle: "Hápticos",
                hapticsDescription: "Retroalimentación sutil para toques, guardado, errores del parser y cambios de tab.",
                enableHaptics: "Activar hápticos",
                privacyTitle: "Privacidad",
                privacyNote: "Pocket Leak guarda los gastos localmente y solo analiza texto que tú pegas manualmente.",
                dataTitle: "Datos",
                exportData: "Exportar datos",
                exportDescription: "Abre Historial para compartir CSV, JSON o el resumen mensual.",
                aboutTitle: "Acerca de",
                aboutDescription: "Hecho para captura rápida y local-first.",
                versionLabel: "Versión",
                resetTitle: "Restablecer",
                resetButton: "Borrar datos locales",
                resetConfirmationTitle: "¿Borrar datos locales?",
                resetConfirmationMessage: "Esto borra los gastos y las metas locales en este dispositivo. No se puede deshacer.",
                deleteAllData: "Borrar todos los datos",
                cancel: "Cancelar",
                backTapTitle: "Quick Add con Back Tap",
                backTapDescription: "iOS no permite que Pocket Leak detecte Back Tap directamente. Crea un Shortcut con Abrir URLs, apunta a pocketleak://quick-add y asígnalo a Back Tap.",
                copyQuickAddURL: "Copiar pocketleak://quick-add",
                copyPrefillURLExample: "Copiar ejemplo de URL prellenada",
                openQuickAddRoute: "Abrir ruta de Captura",
                openQuickAdd: "Abrir Captura",
                openHistoryExports: "Abrir exportaciones",
                openGoals: "Abrir metas",
                openHistory: "Abrir historial",
                openSettings: "Abrir ajustes",
                accessibilitySelected: "Seleccionado",
                accessibilityNotSelected: "No seleccionado",
                openSettingsHint: "Abre la pantalla de ajustes.",
                deleteExpenseHint: "Elimina este gasto guardado.",
                categoryTapHint: "Toca para seleccionar esta categoría.",
                switchTabHint: "Cambia a esta tab.",
                deleteExpenseAccessibilityLabel: "Eliminar gasto",
                appearance: "Apariencia",
                textSize: "Tamaño de texto",
                language: "Idioma",
                resetLocalData: "Borrar datos locales",
                backTapQuickAdd: "Quick Add con Back Tap",
                backTapStepOpenShortcuts: "1. Abre la app Atajos.",
                backTapStepCreateShortcut: "2. Crea un nuevo atajo.",
                backTapStepAddOpenURLs: "3. Agrega la acción Abrir URLs.",
                backTapStepUseQuickAddURL: "4. Define la URL como pocketleak://quick-add.",
                backTapStepOpenAccessibility: "5. Ve a Ajustes > Accesibilidad > Tocar > Back Tap.",
                backTapStepSelectShortcut: "6. Elige Doble toque y selecciona tu atajo.",
                emptyNoExpenses: "Aún no hay gastos.",
                emptyNoInsights: "Aún no hay insights.",
                emptyNoGoals: "Aún no hay metas.",
                dashboardEmptyStateTitle: "Aún no hay gastos",
                dashboardEmptyStateMessage: "Agrega tu primer gasto para desbloquear tendencias, metas y widgets.",
                dashboardEmptyStateAction: "Agregar primer gasto",
                insightsEmptyStateTitle: "Aún no hay insights",
                insightsEmptyStateMessage: "Agrega algunos gastos y Pocket Leak mostrará patrones aquí.",
                insightsEmptyStateAction: "Agregar primer gasto",
                historyEmptyStateTitle: "Aún no hay historial",
                historyEmptyStateMessage: "Empieza con tu primer gasto guardado. Todo se queda local.",
                historyEmptyStateAction: "Agregar primer gasto",
                historyNoResultsTitle: "Sin resultados",
                historyNoResultsMessage: "Prueba otro filtro o restablécelo.",
                historyNoResultsAction: "Restablecer filtros",
                done: "Listo",
                amountTitle: "Monto",
                amountPlaceholder: "0.00",
                quickAddIntro: "Captura un microgasto en menos de 10 segundos.",
                next: "Siguiente",
                categoryTitle: "Categoría",
                categorySubtitle: "Elige la coincidencia más cercana primero. Luego puedes ajustarla.",
                detailsTitle: "Detalles",
                merchantPlaceholder: "Comerciante opcional",
                notePlaceholder: "Nota opcional",
                pasteTitle: "Pegar texto de notificación",
                pasteDescription: "Pega una alerta bancaria o mensaje de transacción. Pocket Leak solo analiza texto que tú pegas, manteniendo el flujo privado.",
                pasteFromClipboard: "Pegar desde portapapeles",
                clipboardEmptyMessage: "Portapapeles vacío. Copia primero una transacción.",
                parseTextButton: "Analizar texto",
                useParsedExpenseButton: "Usar gasto analizado",
                saveExpenseButton: "Guardar gasto",
                expenseSaved: "Gasto guardado",
                saveMissingAmountError: "Ingresa primero un monto.",
                parseNoResultMessage: "No encontré texto útil. Pega una transacción e inténtalo de nuevo.",
                parsedPreviewTitle: "Vista previa analizada",
                parsedPreviewSubtitle: "Revisa los datos extraídos antes de guardar.",
                rawMerchantLabel: "Comerciante original",
                normalizedMerchantLabel: "Comerciante normalizado",
                merchantLabel: "Comerciante",
                confidenceLabel: "Confianza",
                sourceLabel: "Fuente",
                parsedTextSource: "Texto analizado",
                ready: "Listo",
                needsAttention: "Requiere atención",
                missingAmountParseError: "No encontré un monto. Pega el total del cargo e inténtalo de nuevo.",
                dashboardQuickSnapshotTitle: "Resumen rápido",
                dashboardCategoryDistributionTitle: "Distribución por categoría",
                dashboardRecentTrendTitle: "Tendencia reciente",
                dashboardSignalTitle: "Señal de hoy",
                dashboardSignalSubtitle: "Una lectura breve y local de tu patrón de gasto.",
                dashboardGoalsTitle: "Resumen de metas",
                dashboardGoalsSubtitle: "Mantén visibles ambos ritmos de presupuesto sin salir del panel.",
                dashboardGoalsCtaTitle: "Agregar una meta",
                dashboardGoalsCtaSubtitle: "Crea un límite semanal o mensual para ver aquí tu presupuesto restante.",
                dashboardGoalsCtaButton: "Ir a Metas",
                dashboardNoCategoryDistribution: "Agrega algunos gastos para ver la categoría principal.",
                dashboardNoRecentTrend: "Agrega gastos para ver los últimos 14 días.",
                historyExportsTitle: "Exportaciones",
                historyFilterTitle: "Historial",
                historyCategoryTitle: "Categoría",
                historyResetFilters: "Restablecer",
                historyNoMatchingExpenses: "Prueba otra categoría o filtro de tiempo.",
                exportCSV: "Exportar CSV",
                exportJSON: "Exportar JSON",
                exportMonthlySummary: "Compartir resumen mensual",
                shareSummaryButton: "Compartir resumen",
                shareSummaryWeeklyCardTitle: "Resumen semanal",
                shareSummaryMonthlyCardTitle: "Resumen mensual",
                shareSummaryGoalCardTitle: "Progreso de meta",
                shareSummaryTopCategoryCardTitle: "Categoría principal",
                shareSummaryBadgeWeekly: "Semanal",
                shareSummaryBadgeMonthly: "Mensual",
                shareSummaryBadgeGoal: "Meta",
                shareSummaryBadgeTopCategory: "Principal",
                shareSummaryTopCategoryChipPrefix: "Principal",
                shareSummaryTopCategoryShareTemplate: "%@ del total",
                shareSummaryTopCategoryCountTemplate: "%d gastos",
                shareSummaryWeeklyMessage: "Una vista rápida de tu semana.",
                shareSummaryMonthlyMessage: "Una vista rápida de tu mes.",
                shareSummaryGoalMessage: "Tu progreso de meta de un vistazo.",
                shareSummaryTopCategoryMessage: "Tu mayor fuga de este mes.",
                insightsWeeklyTotalsTitle: "Totales semanales",
                insightsCategoryBreakdownTitle: "Desglose por categoría",
                insightsNoCategoryBreakdown: "Aún no hay desglose.",
                trendsTitle: "Tendencias",
                trendsSubtitle: "Comparaciones locales y claras de los últimos periodos.",
                trendTodayVsYesterdayTitle: "Hoy vs Ayer",
                trendWeekVsLastWeekTitle: "Esta semana vs la pasada",
                trendMonthVsLastMonthTitle: "Este mes vs el pasado",
                trendDailyAverageWeekTitle: "Promedio diario de la semana",
                trendTopCategoryComparisonTitleTemplate: "%@ vs %@",
                trendCurrentLabel: "Actual",
                trendPreviousLabel: "Anterior",
                trendNoPreviousDataMessage: "Aún no hay datos previos.",
                trendHigherMessageTemplate: "%@ más que el periodo anterior",
                trendLowerMessageTemplate: "%@ menos que el periodo anterior",
                trendFlatMessage: "Casi igual que el periodo anterior.",
                weeklyDigestTitle: "Resumen semanal",
                weeklyDigestSubtitle: "Un resumen rápido de cómo va la semana.",
                weeklyDigestEmptyTitle: "El resumen semanal aparecerá aquí",
                weeklyDigestEmptyMessage: "Agrega algunos gastos durante la semana y Pocket Leak construirá un resumen claro automáticamente.",
                weeklyDigestEmptyAction: "Agregar primer gasto",
                weeklyDigestDateRangeTemplate: "%@ - %@",
                weeklyDigestExpenseCountTemplate: "%d gastos esta semana",
                weeklyDigestTopCategoryLabel: "Categoría principal",
                weeklyDigestAverageDailyLabel: "Promedio diario",
                weeklyDigestLargestExpenseLabel: "Gasto más alto",
                weeklyDigestGoalStatusLabel: "Estado de meta",
                weeklyDigestBestInsightLabel: "Mejor insight",
                weeklyDigestComparisonLabel: "Comparado con la semana pasada",
                weeklyDigestNoComparisonMessage: "Aún no hay comparación semana a semana.",
                weeklyDigestShareButton: "Compartir resumen",
                smartAlertsTitle: "Alertas inteligentes",
                smartAlertsSubtitle: "Alertas en vivo basadas en tus patrones locales de gasto.",
                smartAlertsDescription: "Muestra alertas dentro de la app para riesgo, picos y tendencias positivas.",
                enableSmartAlerts: "Activar alertas inteligentes",
                smartAlertsDismiss: "Descartar",
                smartAlertsNoDataTitle: "Aún no hay gasto",
                smartAlertsNoDataMessage: "Agrega tu primer gasto y Pocket Leak empezará a mostrar alertas aquí.",
                smartAlertsGoalRiskTitle: "Meta en riesgo",
                smartAlertsGoalWatchWeeklyMessageTemplate: "%@ está cerca del límite. Te quedan %@/día.",
                smartAlertsGoalWatchMonthlyMessageTemplate: "%@ está cerca del límite. Te quedan %@/día.",
                smartAlertsGoalRiskWeeklyMessageTemplate: "%@ tiene riesgo de pasarse por %@.",
                smartAlertsGoalRiskMonthlyMessageTemplate: "%@ tiene riesgo de pasarse por %@.",
                smartAlertsGoalOverWeeklyMessageTemplate: "%@ ya está por encima por %@.",
                smartAlertsGoalOverMonthlyMessageTemplate: "%@ ya está por encima por %@.",
                smartAlertsTodayAboveAverageTitle: "Hoy va alto",
                smartAlertsTodayAboveAverageMessageTemplate: "El gasto de hoy está %@ por encima de tu promedio diario (%@).",
                smartAlertsCategorySpikeTitle: "Pico por categoría",
                smartAlertsCategorySpikeMessageTemplate: "%@ subió %@ vs la semana pasada (%@).",
                smartAlertsPositiveTrendTitle: "Tendencia positiva",
                smartAlertsPositiveTrendMessageTemplate: "Gastaste %@ menos que la semana pasada (%@).",
                smartInsightsTitle: "Insights inteligentes",
                smartInsightsSubtitle: "Patrones locales de tus gastos guardados.",
                smartInsightsNoDataTitle: "Aún no hay insights",
                smartInsightsNoDataMessage: "Agrega algunos gastos y Pocket Leak empezará a mostrar patrones aquí.",
                smartInsightsTopCategoryWeekTitle: "Categoría principal de la semana",
                smartInsightsTopCategoryMonthTitle: "Categoría principal del mes",
                smartInsightsTopCategoryWeekMessage: "%@ representa %@ de tus fugas registradas esta semana.",
                smartInsightsTopCategoryMonthMessage: "%@ representa %@ de tus fugas registradas este mes.",
                smartInsightsDailyAverageWeekTitle: "Promedio diario de la semana",
                smartInsightsDailyAverageMonthTitle: "Promedio diario del mes",
                smartInsightsDailyAverageWeekMessage: "Promedias %@ por día esta semana.",
                smartInsightsDailyAverageMonthMessage: "Promedias %@ por día este mes.",
                smartInsightsSpendingIncreaseTitle: "El gasto subió",
                smartInsightsSpendingDecreaseTitle: "El gasto bajó",
                smartInsightsSpendingIncreaseMessage: "Gastaste %@ más que la semana pasada (%@).",
                smartInsightsSpendingDecreaseMessage: "Gastaste %@ menos que la semana pasada (%@).",
                smartInsightsGoalRiskTitle: "Meta en riesgo",
                smartInsightsPositiveTrendTitle: "En control",
                smartInsightsNeutralTitle: "Neutral",
                smartInsightsGoalRiskWeeklyLimitReachedMessage: "Estás %@ por encima de tu límite semanal.",
                smartInsightsGoalRiskMonthlyLimitReachedMessage: "Estás %@ por encima de tu límite mensual.",
                smartInsightsGoalRiskWeeklyCloseToLimitMessage: "Te quedan %@ esta semana.",
                smartInsightsGoalRiskMonthlyCloseToLimitMessage: "Te quedan %@ este mes.",
                goalsWeeklyTitle: "Meta semanal",
                goalsMonthlyTitle: "Meta mensual",
                goalsCreateWeekly: "Crear meta semanal",
                goalsCreateMonthly: "Crear meta mensual",
                goalsEdit: "Editar",
                goalsRemove: "Eliminar",
                goalsLimitLabel: "Límite",
                goalsSpentLabel: "Gastado",
                goalsRemainingLabel: "Restante",
                goalsPercentUsedLabel: "% usado",
                goalsDaysLeftLabel: "Días restantes",
                goalsRemainingDailyBudgetLabel: "Restante por día",
                goalsProjectedMonthSpendLabel: "Proyección mensual",
                goalsStatusOnTrack: "En control",
                goalsStatusCloseToLimit: "Cerca del límite",
                goalsStatusLimitReached: "Límite alcanzado",
                goalsNoGoalStatus: "Sin meta",
                goalsNoGoalMessage: "Crea un límite semanal o mensual para seguir tu progreso localmente.",
                goalsPeriodThisWeek: "esta semana",
                goalsPeriodThisMonth: "este mes",
                goalsWeeklyOnTrackMessageTemplate: "Te quedan %@ por día esta semana.",
                goalsWeeklyCloseToLimitMessage: "Te estás acercando. Mantén el resto de la semana intencional.",
                goalsWeeklyLimitReachedMessage: "El gasto semanal alcanzó el límite. Pausa antes del siguiente ciclo.",
                goalsMonthlyOnTrackMessageTemplate: "Te quedan %@ por día este mes. A este ritmo gastarías %@ este mes.",
                goalsMonthlyCloseToLimitMessage: "Estás en zona de precaución. Vigila el presupuesto restante.",
                goalsMonthlyLimitReachedMessage: "Este mes alcanzó el límite. Haz que el siguiente gasto sea intencional.",
                goalsEmptyWeekly: "Todavía no hay meta semanal.",
                goalsEmptyMonthly: "Todavía no hay meta mensual.",
                goalsEditorTitle: "Editor de metas",
                goalsGoalLogicDescription: "Mantente por debajo del límite seleccionado por semana o por mes.",
                goalsForecastTitle: "Pronóstico",
                goalsForecastAtThisPaceTemplate: "A este ritmo, terminarás en %@.",
                goalsForecastDailyBudgetTemplate: "Te quedan %@/día.",
                goalsForecastStayUnderTemplate: "Se proyecta que te mantengas por debajo por %@.",
                goalsForecastGoOverTemplate: "Se proyecta que te pases por %@.",
                goalsForecastOverSummary: "Ya estás por encima por %@.",
                goalForecastStatusSafe: "Seguro",
                goalForecastStatusWatch: "Atento",
                goalForecastStatusRisk: "En riesgo",
                goalForecastStatusOver: "Excedido",
                dashboardGoalAtRiskTitleTemplate: "%@ en riesgo",
                dashboardGoalAtRiskSubtitleTemplate: "Te quedan %@/día.",
                goalsRemoveConfirmationTitle: "¿Eliminar meta de gasto?",
                goalsRemoveConfirmationMessage: "Esto elimina la meta local de este dispositivo."
            )
        }
    }
}

extension AppLanguage {
    static var current: AppLanguage {
        let raw = UserDefaults.standard.string(forKey: AppPreferenceKeys.language) ?? AppLanguage.english.rawValue
        return AppLanguage(rawValue: raw) ?? .english
    }
}

enum AppTypography {
    static func scale(for textSize: AppTextSize) -> CGFloat {
        textSize.scale
    }

    static func scaled(_ value: CGFloat, using textSize: AppTextSize) -> CGFloat {
        value * textSize.scale
    }
}

private struct AppAppearanceKey: EnvironmentKey {
    static let defaultValue: AppAppearance = .dark
}

private struct AppTextSizeKey: EnvironmentKey {
    static let defaultValue: AppTextSize = .medium
}

private struct AppLanguageKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .english
}

private struct AppStringsKey: EnvironmentKey {
    static let defaultValue: AppStrings = .current()
}

extension EnvironmentValues {
    var appAppearance: AppAppearance {
        get { self[AppAppearanceKey.self] }
        set { self[AppAppearanceKey.self] = newValue }
    }

    var appTextSize: AppTextSize {
        get { self[AppTextSizeKey.self] }
        set { self[AppTextSizeKey.self] = newValue }
    }

    var appLanguage: AppLanguage {
        get { self[AppLanguageKey.self] }
        set { self[AppLanguageKey.self] = newValue }
    }

    var pocketLeakStrings: AppStrings {
        get { self[AppStringsKey.self] }
        set { self[AppStringsKey.self] = newValue }
    }
}
