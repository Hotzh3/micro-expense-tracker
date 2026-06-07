# Technical Constraints

## iOS Notification Access

Normal third-party iOS apps cannot arbitrarily read other apps' notifications. Pocket Leak must not attempt to scrape bank notifications as a core feature.

## Recommended Capture Strategy

- Manual quick add as the core flow
- Back Tap through a user-created Shortcut
- URL scheme for fast invocation
- Optional paste-based parsing only as an editable helper

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

## Manual Xcode Requirement

The project is generated with XcodeGen and built from the checked-in source files and manifest.
