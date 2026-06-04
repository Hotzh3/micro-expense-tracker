# Technical Constraints

## iOS Notification Access

The MVP should not assume access to push notifications from other apps. iOS does not provide a general-purpose API for reading third-party app notifications into another app. That means J Tap should not be built around bank notification scraping as the primary capture path.

## Recommended Capture Strategy

- Manual quick add as the core flow
- Back Tap as a shortcut entry point later
- App Intents and Shortcuts for fast invocation later
- Optional paste or shared-text parsing only if implemented carefully

## Persistence Constraint

The current phase should not implement real persistence yet. Sample data and in-memory state are enough for the initial product and UI foundation.

## Scope Constraint

The repository should remain focused on the first three phases only:

- Product definition
- App foundation
- Minimal design system skeleton

## Privacy Constraint

The product should stay local-first in the MVP and avoid collecting sensitive banking data by default.

## Manual Xcode Requirement

If no Xcode project exists, the Swift files in this repository are intended to be copied into a manually created iOS SwiftUI app target.
