# Technical Constraints

## iOS Notification Access

Normal third-party iOS apps cannot arbitrarily read other apps' notifications. Pocket Leak must not attempt to scrape bank notifications as a core feature.

Notification permissions in iOS apply to the app's own notifications, not to reading notifications from other apps.

## Recommended Capture Strategy

- Manual quick add as the core flow
- Back Tap through a user-created Shortcut
- URL scheme for fast invocation, including `pocketleak://parse?text=...`
- Optional paste-based parsing only after an explicit tap
- Future user-driven import flows should require explicit sharing or export from the source app

## Persistence Constraint

Pocket Leak stores expenses locally on device only. No cloud sync, sign-in, external database, or paid API is part of the product.

## Scope Constraint

The repository should stay focused on the local-first Pocket Leak scope:

- Product definition
- App foundation
- Local persistence
- Shortcut-ready capture
- Manual parsing and insights

## Privacy Constraint

The product should stay local-first and avoid collecting sensitive banking data by default. The manual parser is privacy-safe because the user explicitly pastes the text they want parsed.

- The app must not read cross-app notifications automatically.
- The app must not poll the clipboard.
- Clipboard intake is allowed only when the user taps an explicit button.
- URL-based text intake is allowed because the user or Shortcut explicitly passes the text into Pocket Leak.

UI copy should stay aligned with this constraint: "Pocket Leak stores expenses locally and only parses text you paste manually."

## Manual Xcode Requirement

The project is generated with XcodeGen and built from the checked-in source files and manifest.
