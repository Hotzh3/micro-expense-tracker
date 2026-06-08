# Portfolio Notes

## Product Problem

Pocket Leak solves a simple but real problem: small daily purchases are easy to forget, and traditional budgeting apps are too heavy for quick capture.

## iOS Constraints

- Third-party iOS apps cannot read arbitrary bank notifications.
- The app therefore stays local-first and user-driven.
- Shortcut and URL-scheme entry points are used instead of notification scraping.

## Privacy-Safe Design

- All expense data stays on device.
- The parser only works on text the user explicitly pastes.
- No bank account access, paid API, or cloud sync is required for the core workflow.

## Technical Architecture

- SwiftUI app shell with a tabbed local-first workflow
- Observable view model for capture, charts, and export
- Foundation-based parsing and CSV/JSON export services
- Swift Charts for dashboard and insights visualization
- URL routing for Quick Add entry points
- WidgetKit foundation with static demo data until shared storage is added

## Why It Is Portfolio Worthy

- It demonstrates product judgment under platform constraints.
- It balances utility, privacy, and visual polish.
- It shows a complete iOS feature slice: capture, analytics, export, shortcuts, and extension architecture.
- It is small enough to understand quickly but broad enough to show real native app engineering.
