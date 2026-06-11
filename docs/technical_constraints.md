# Technical Constraints

## iOS Data Access

Pocket Leak must stay within standard iOS privacy boundaries. It should not attempt to read other apps' notifications, bank data, or private system state.

## Supported Capture Paths

- manual Quick Add
- user-pasted text
- explicit Share Extension handoff
- user-created Shortcut / Back Tap flow

## Local-First Constraint

- expenses stay on device
- summaries are derived locally
- widgets only read local summary data
- exports are generated on device
- demo data is synthetic and local only

## Performance Constraint

Large local datasets should not turn Dashboard, History, Goals, or Insights into expensive re-render loops. Cached summaries and limited recent lists are preferred over repeated filtering inside SwiftUI bodies.

## Distribution Constraint

- GitHub can share the source code and docs
- GitHub does not install the app on an iPhone with one click
- a physical iPhone build requires a Mac and Xcode
- TestFlight and App Store distribution require the Apple Developer Program

## Privacy Constraint

Pocket Leak stores expenses locally and only parses text the user pastes or explicitly shares.

- no automatic clipboard polling
- no cloud sync
- no login
- no third-party analytics requirement for core use
- no bank notification scraping

## Manual Testing Constraint

The project is built with XcodeGen and should be validated through local Xcode builds and simulator or device QA, not through a hosted deployment pipeline.

