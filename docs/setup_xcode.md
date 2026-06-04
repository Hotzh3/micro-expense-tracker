# Manual Xcode Setup

This repository does not contain an Xcode project yet. Create a new SwiftUI iOS app in Xcode and copy these files into it.

## Steps

1. Open Xcode.
2. Choose File > New > Project.
3. Select iOS > App.
4. Set the product name to `J Tap`.
5. Use SwiftUI for the interface and Swift for the language.
6. Save the new project somewhere local.
7. Create these groups or folders in the Xcode project:
   - App
   - Models
   - Views
   - ViewModels
   - Services
   - Theme
8. Copy the Swift files from this repository into the matching groups.
9. Replace the default app entry file with `JTapApp.swift`.
10. Set `RootView` as the root screen.
11. Run the app in an iPhone simulator.

## File Placement

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

After copying the files, the app should build as a simple SwiftUI shell with in-memory sample data and no persistence, charts, or App Intents yet.
