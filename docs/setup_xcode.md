# XcodeGen Setup

This repository is configured to generate the Xcode project reproducibly with XcodeGen.

## Install

1. Install Xcode from the Mac App Store or Apple Developer downloads.
2. Install XcodeGen with Homebrew:
   - `brew install xcodegen`

## Generate the Project

1. From the repository root, run:
   - `xcodegen generate`
2. Open the generated project:
   - `open JTap.xcodeproj`
3. Select the `JTap` scheme and run it in an iPhone simulator.

## Manual File Layout

The source files in this repository are already arranged for the XcodeGen target:

- `App/JTapApp.swift`
- `Models/Expense.swift`
- `Models/ExpenseCategory.swift`
- `Views/RootView.swift`
- `Views/QuickAddView.swift`
- `Views/DashboardView.swift`
- `Views/HistoryView.swift`
- `Views/InsightsView.swift`
- `ViewModels/ExpenseViewModel.swift`
- `Services/ExpenseStore.swift`
- `Theme/AppTheme.swift`
- `Theme/GlassCardView.swift`
- `Theme/PrimaryButton.swift`
- `Theme/CategoryPillView.swift`
- `Theme/MetricCardView.swift`
- `Theme/EmptyStateView.swift`

## Expected Result

After running XcodeGen, the app should build as a SwiftUI iPhone app with local persistence, history filters, insights, and a `jtap://` URL scheme for shortcut-style opening. The user-facing app name in the UI should read Pocket Leak.
