# Pocket Leak

Pocket Leak is a minimalist iPhone micro-expense tracker for fast daily spending capture.

## What It Does

Pocket Leak helps users log small spending leaks quickly: coffee, snacks, rides, convenience-store purchases, and other daily micro-expenses.

## Why It Matters

Micro-expenses are easy to forget. Pocket Leak keeps the capture flow short, local-first, and private so users can record spending before the details disappear.

## Features

- Quick Add for amount, category, merchant, and note
- Local persistence with JSON storage in the app container
- Dashboard totals for today, this week, and this month
- History with category and time filters plus delete support
- Insights with average spend, projected monthly spend, Smart Insights, top categories, category breakdowns, and visual charts
- Goals for weekly or monthly spending limits with progress and risk states
- Settings for appearance, text size, language, privacy notes, and Back Tap setup
- CSV, JSON, and monthly summary export through the iOS share sheet
- Manual pasted-text parser for transaction alerts and pasted receipts
- Shortcut and Back Tap readiness through the `jtap://` and `pocketleak://` URL schemes
- Widget foundation for a future Home Screen summary
- Minimal black-and-white SwiftUI layout tuned for iPhone

## Visual Identity

Pocket Leak currently uses a temporary black app icon with a white `PL` monogram. The mark is intentionally minimal and premium while the final branding direction is still being finalized.

## Screenshots

Screenshots are not checked in yet. Suggested placeholders for future captures:

- `docs/screenshots/quick-add.png`
- `docs/screenshots/dashboard.png`
- `docs/screenshots/history-export.png`
- `docs/screenshots/insights.png`

## Tech Stack

- Swift
- SwiftUI
- Swift Charts
- XcodeGen project generation
- Local JSON persistence
- Manual text parsing with Foundation regular expressions

## Current Status

The app has a working SwiftUI foundation, local storage, Quick Add, Dashboard, History, Insights, Goals, Smart Insights, smart pasted-text parsing, URL-scheme launch readiness, chart-based insights, CSV/JSON/monthly-summary export, and a widget foundation. The current focus is layout polish, settings, and device-ready documentation.

## Run Locally

1. Install Xcode and XcodeGen.
2. From the repo root, run `xcodegen generate`.
3. Open `JTap.xcodeproj`.
4. Build and run the `JTap` scheme in an iPhone simulator.
5. For real-device setup, see [docs/iphone_testing.md](docs/iphone_testing.md).

## Shortcuts / Back Tap Workflow

Pocket Leak does not read bank notifications automatically. The supported flow is:

1. User double taps the back of the iPhone.
2. iOS runs a Shortcut that opens Pocket Leak Quick Add.
3. The user logs the expense manually or pastes transaction text for parsing help.

See [docs/shortcuts.md](docs/shortcuts.md) for setup details.

## Privacy And iOS Limitations

- Pocket Leak stores expenses locally on device.
- There is no bank integration or cloud sync.
- iOS does not allow arbitrary third-party apps to read system notifications.
- The parser only works with text the user explicitly provides.

## Roadmap

See [docs/roadmap.md](docs/roadmap.md) for the current product roadmap and completed phases.
