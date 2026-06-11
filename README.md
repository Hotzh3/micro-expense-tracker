# Pocket Leak

Pocket Leak is a local-first iPhone micro-expense tracker for fast capture, clear spending signals, and polished portfolio demos.

It is designed for people who want to understand small daily spending without connecting bank accounts, creating an account, or sending data to the cloud.

## The Problem

Tiny purchases are easy to forget and hard to summarize later. Coffee, snacks, rides, subscriptions, and convenience-store stops add up quietly. Pocket Leak reduces capture friction so those expenses can be logged quickly and reviewed later with useful local summaries.

## Screenshots

Placeholder assets live under:

- `docs/assets/screenshots/quick-add.png`
- `docs/assets/screenshots/dashboard.png`
- `docs/assets/screenshots/goals.png`
- `docs/assets/screenshots/history.png`
- `docs/assets/screenshots/settings.png`

Use [`docs/screenshot_plan.md`](docs/screenshot_plan.md) for capture guidance and [`docs/demo_script.md`](docs/demo_script.md) for the one-minute demo flow.
See also [`docs/portfolio_case_study.md`](docs/portfolio_case_study.md), [`docs/github_project_polish.md`](docs/github_project_polish.md), and [`docs/free_distribution_guide.md`](docs/free_distribution_guide.md).

## Core Features

- Quick Add for amount, category, merchant, and note
- Manual parser for pasted or shared transaction text
- Dashboard with totals, category distribution, trend bars, signals, and recent activity
- History with filters, sorting, and export-friendly browsing
- Goals for weekly and monthly spending limits
- Category budgets for Coffee, Food, Transport, Shopping, and more
- Recurring expenses for upcoming fixed charges
- Insights for averages, comparisons, and spend patterns
- Widget support for glanceable local summaries
- Share Extension for explicit text handoff
- Local backup, CSV export, JSON export, and PDF export
- Demo Mode for synthetic screenshot and video data

## Demo Flow

1. Open Settings.
2. Load Demo Data from the Demo Mode section.
3. Return to Dashboard and show the donut chart, trend, goals, budgets, and recurring items.
4. Open History and scroll through the synthetic data set.
5. Open Goals and Insights to show progress and category patterns.
6. Reset Demo Data or Clear All Data when you are done.

See [`docs/demo_data_plan.md`](docs/demo_data_plan.md) and [`docs/demo_script.md`](docs/demo_script.md).

## Tech Stack

- Swift
- SwiftUI
- WidgetKit
- UserNotifications
- Foundation parsing and formatting helpers
- Core Graphics and UIKit-based PDF export
- XcodeGen project generation
- Local JSON persistence

## Architecture

- `ViewModels/ExpenseViewModel.swift` owns the app state and local summaries
- `Services/` contains persistence, demo generation, export, backup, formatters, and notification helpers
- `Views/` contains the main SwiftUI screens
- `Widgets/` contains the widget target
- `ShareExtension/` contains explicit shared-text intake
- `Theme/` contains visual tokens, app settings, and localization strings

The app uses cached summaries and reusable helpers so Dashboard, History, Goals, Insights, and widgets do not re-run heavy work on every render.

## Privacy

- Expenses stay on device
- No login is required
- No cloud sync is used
- No analytics SDK is required for core use
- No bank scraping is performed
- Manual parsing only runs on text the user pastes or shares intentionally

Read [`docs/privacy_summary.md`](docs/privacy_summary.md) and [`docs/technical_constraints.md`](docs/technical_constraints.md) for the full privacy and platform constraints.

## iOS Limitations

- Pocket Leak cannot read other apps' notifications automatically
- Back Tap must be wired through a user-created Shortcut
- Share Extension intake is explicit only
- Widgets can show summaries, not hidden account data
- Free installation on a physical iPhone still requires a Mac with Xcode
- TestFlight and App Store distribution require the Apple Developer Program

See [`docs/free_distribution_guide.md`](docs/free_distribution_guide.md) for the free local development limitations.

## Run Locally

1. Install Xcode and XcodeGen.
2. Generate the project with `xcodegen generate`.
3. Open `JTap.xcodeproj`.
4. Build and run the shared `JTap` scheme.

## Running Locally For Free

If you want to try Pocket Leak without paying for the Apple Developer Program, use these guides:

- [`docs/setup_xcode.md`](docs/setup_xcode.md)
- [`docs/free_distribution_guide.md`](docs/free_distribution_guide.md)
- [`docs/iphone_testing.md`](docs/iphone_testing.md)

## XcodeGen Setup

The generated Xcode project is checked in, but the source of truth is the XcodeGen configuration in the repo.

```bash
xcodegen generate
```

After regenerating, open `JTap.xcodeproj` and build the `JTap` scheme in Xcode.

## Testing and Stress Testing

- `docs/stress_testing_plan.md` describes the high-volume local stress scenarios
- `docs/performance_baseline.md` records the current manual performance baseline
- Debug builds include synthetic demo and stress workflows for local validation

Suggested commands:

```bash
xcodegen generate
xcodebuild -project JTap.xcodeproj -scheme JTap -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/JTapDerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project JTap.xcodeproj -scheme JTap -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/JTapReleaseDerivedData CODE_SIGNING_ALLOWED=NO build
```

## Roadmap

See [`docs/roadmap.md`](docs/roadmap.md) for the current roadmap, completed work, and next steps.

## Future Cloud/Social Roadmap

Cloud sync and social features are intentionally documented as future work only. The current app is local-first and does not require accounts or remote services.

See [`docs/cloud_social_roadmap.md`](docs/cloud_social_roadmap.md) for the future phase plan, and [`docs/cloud_architecture_options.md`](docs/cloud_architecture_options.md) for the architecture tradeoffs.

## Project Status

Pocket Leak is a polished local-first portfolio build, not a published App Store release.

Current strengths:

- strong SwiftUI foundation
- local persistence
- widget and share extension support
- demo mode for screenshots and video
- stress testing coverage for large local datasets

## Disclaimer

Pocket Leak does not scrape bank data, does not read other apps' notifications, and does not depend on cloud services. The product is intentionally local-first and explicit about any text the user chooses to paste or share.
