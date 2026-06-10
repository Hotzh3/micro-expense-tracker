# TestFlight Guide

Pocket Leak can be prepared for TestFlight once Apple Developer signing is available.

## Requirements

- Apple Developer Program membership is required for TestFlight uploads.
- A Personal Team can build and install locally, but it is not enough for TestFlight distribution.
- App Store Connect access must be set up for the Apple ID that will upload the build.
- Bundle identifiers must remain stable once the app is registered in App Store Connect.

## Current Build Identity

- App bundle identifier: `com.josema.JTap`
- Widget bundle identifier: `com.josema.JTap.PocketLeakWidget`
- Share Extension bundle identifier: `com.josema.JTap.PocketLeakShareExtension`
- Marketing version: `0.5.0`
- Build number: `50`

## Archive Flow

1. Open `JTap.xcodeproj` in Xcode.
2. Select the shared `JTap` scheme.
3. Use `Product > Archive`.
4. Open the Organizer when the archive finishes.
5. Choose `Distribute App`.
6. Select `App Store Connect`.
7. Select `Upload`.
8. Resolve signing issues if Xcode prompts for them.

## Signing Notes

- Local builds can use automatic signing with a Personal Team.
- TestFlight requires a paid Apple Developer Program team with matching identifiers and capabilities.
- If signing fails:
  - verify the team in the Signing & Capabilities tab
  - confirm the app, widget, and share extension all use the same Apple Developer Team
  - confirm App Groups is enabled for the app and extensions when required
  - regenerate the project with `xcodegen generate` if `project.yml` changed

## Bundle ID Notes

- Do not change the bundle identifiers after TestFlight metadata is created unless you intend to create a new app record.
- Keep the widget and share extension bundle IDs nested under the app bundle ID.
- If a new Apple Developer Team is used, the bundle IDs can stay the same but the capabilities may need to be re-added in the portal.

## App Groups

- Pocket Leak uses a shared App Group for the widget and share extension handoff.
- If the App Group capability is not applied automatically, enable it manually in Apple Developer / Xcode for:
  - `JTap`
  - `PocketLeakWidget`
  - `PocketLeakShareExtension`
- The group identifier used by the repo is `group.com.josema.PocketLeak`.

## Personal Team vs Developer Program

- Personal Team:
  - good for local install and simulator/device debugging
  - may not support the capabilities needed for TestFlight
  - cannot upload to TestFlight
- Apple Developer Program:
  - required for Archive upload to App Store Connect
  - supports TestFlight internal and external testing
  - supports stable distribution signing

## Privacy Manifest

- Pocket Leak does not rely on third-party SDKs or required-reason APIs in the current codebase.
- A privacy manifest is not currently required by the app code itself.
- Local notifications are user-owned reminders and do not read other apps' content.
- The share extension only receives user-shared text and never scrapes notifications.
- If third-party SDKs are added later, re-check Apple privacy manifest requirements.

## App Store Connect

- Create or open the app record using the app bundle ID above.
- Upload the archive from Xcode Organizer.
- Wait for processing to finish.
- Enable TestFlight internal testing first.
- Add external testers only after build processing succeeds and review requirements are satisfied.

## QA Before Upload

- Run a clean Release build.
- Validate Quick Add, Parse Text, Goals, History, Dashboard, Insights, Widgets, Share Extension, and local notifications.
- Verify the release version and build number in Settings.
- Confirm no debug-only behavior is needed for normal release operation.
