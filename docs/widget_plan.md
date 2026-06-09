# Widget Foundation

Pocket Leak includes a WidgetKit extension that can read a shared summary written by the main app. If App Group is not enabled, the widget falls back to a demo/empty state instead of crashing.

## Current State

- The widget builds as a lightweight foundation.
- The main app writes a shared `WidgetSummary` snapshot through `WidgetSummaryStore`.
- The widget reads the same summary from the App Group container when available.
- It falls back to demo/empty states when the shared container cannot be read.
- It supports small, medium, and large families with black-and-white layouts.
- The widget can show today, week, month, top category, weekly/monthly goal status, and the top 3 categories.

## Future Work

- Add richer goal progress rendering once widgets need limit percentages.
- Surface a live weekly or monthly trend once the shared payload grows.
- Add optional tap-through deep links from the widget to Quick Add or Goals.

## App Group Setup

- App Group identifier: `group.com.josema.PocketLeak`
- The project is prepared with entitlements in `JTap.entitlements` and `Widgets/PocketLeakWidget/PocketLeakWidget.entitlements`.
- If Personal Team signing blocks the capability, enable App Groups manually in Xcode for both targets and confirm the App Group exists in the Apple Developer portal.

## Troubleshooting

- If the widget only shows demo data, verify the App Group entitlement is enabled for both targets.
- If the widget shows an empty state, open Pocket Leak and save at least one expense so the app can write the shared summary.
- If the widget does not refresh, confirm the main app is calling `WidgetCenter.shared.reloadAllTimelines()` after expense or goal changes.
