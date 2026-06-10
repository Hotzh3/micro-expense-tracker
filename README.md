# Pocket Leak

Pocket Leak is a privacy-first iPhone micro-expense tracker for fast daily spending capture, lightweight insights, and device-local reporting.

## What It Is

Pocket Leak helps users log the small purchases that quietly add up: coffee, snacks, rides, convenience-store purchases, subscriptions, and everyday spending leaks.

The app is designed to be fast enough for real-world use, local-first by default, and easy to explain in a portfolio or App Store context.

## Core Features

- Quick Add for amount, merchant, category, and note
- Manual parse flow for pasted transaction text
- Dashboard totals for today, this week, and this month
- History with filters and delete support
- Insights with averages, projections, category breakdowns, and Smart Insights
- Weekly and monthly goals with progress and risk states
- Local notifications for daily check-in, goal warnings, and weekly digest reminders
- CSV, JSON, and PDF export
- Share Extension for user-shared text intake
- Widget support for glanceable spending summary
- Settings for appearance, text size, language, notifications, and privacy-oriented guidance

## Privacy-First Approach

- Expenses are stored locally on device.
- No account sign-in is required.
- No cloud sync is used.
- No push notifications are used.
- No analytics SDKs are required for core product use.
- Pocket Leak does not read other apps' notifications automatically.
- Any text parsing happens only when the user pastes or shares text intentionally.

See [docs/privacy_summary.md](docs/privacy_summary.md) and [docs/technical_constraints.md](docs/technical_constraints.md) for the privacy model and iOS limitations.

## App Store And Portfolio Material

- [App Store metadata draft](docs/app_store_metadata.md)
- [Screenshot plan](docs/screenshot_plan.md)
- [Demo data plan](docs/demo_data_plan.md)
- [Release checklist](docs/release_checklist.md)
- [TestFlight guide](docs/testflight_guide.md)

Suggested screenshot placeholders:

- `docs/screenshots/quick-add.png`
- `docs/screenshots/parser.png`
- `docs/screenshots/dashboard.png`
- `docs/screenshots/goals.png`
- `docs/screenshots/insights.png`
- `docs/screenshots/widgets.png`
- `docs/screenshots/settings.png`
- `docs/screenshots/share-export.png`

## Tech Stack

- Swift
- SwiftUI
- Swift Charts
- WidgetKit
- UserNotifications
- XcodeGen project generation
- Local JSON persistence
- PDF generation with Core Graphics / UIKit rendering
- Manual text parsing with Foundation

## Current Status

Pocket Leak already includes the core iPhone flows needed for a strong release demo:

- Quick Add
- Dashboard
- History
- Goals
- Insights
- Widgets
- Share Extension
- Local notifications
- CSV / JSON / PDF export

The remaining work is mainly release packaging, metadata, QA, and distribution readiness.

## Visual Identity

Pocket Leak currently uses a minimal black app icon with a white `PL` monogram. The icon direction is intentionally restrained so the product feels calm and utility-first.

## Run Locally

1. Install Xcode and XcodeGen.
2. From the repo root, run `xcodegen generate`.
3. Open `JTap.xcodeproj`.
4. Build and run the shared `JTap` scheme.
5. For real-device guidance, see [docs/iphone_testing.md](docs/iphone_testing.md).

## Back Tap / Shortcut Flow

Pocket Leak does not read bank notifications automatically. The supported quick-capture flow is:

1. User double taps the back of the iPhone.
2. iOS runs a Shortcut that opens Pocket Leak.
3. The user logs the expense manually, pastes text, or shares text into the app.

See [docs/shortcuts.md](docs/shortcuts.md) for setup details.

## Roadmap

See [docs/roadmap.md](docs/roadmap.md) for the product roadmap and completed phases.
