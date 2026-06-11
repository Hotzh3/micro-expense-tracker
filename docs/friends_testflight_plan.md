# Friends TestFlight Plan

Pocket Leak can be shared with friends through TestFlight once the app is uploaded to App Store Connect with a paid Apple Developer Program account.

## What Is Required

- Apple Developer Program membership
- App Store Connect access for the Apple ID that uploads builds
- A valid app record for `com.josema.JTap`
- Matching bundle identifiers for the app, widget, and share extension
- Working App Groups capability for the app targets that need shared local data

## Bundle IDs

- App: `com.josema.JTap`
- Widget: `com.josema.JTap.PocketLeakWidget`
- Share Extension: `com.josema.JTap.PocketLeakShareExtension`

## Capabilities To Verify

- App Groups for the main app, widget, and share extension
- Local Notifications entitlement and permission flow
- Face ID usage description if App Lock is enabled
- Widget extension signing
- Share extension signing

## Upload Flow

1. Open the shared `JTap` scheme in Xcode.
2. Select `Any iOS Device` as the build destination.
3. Use `Product > Archive`.
4. In Organizer, choose `Distribute App`.
5. Select `App Store Connect`.
6. Select `Upload`.
7. Fix any signing or entitlement issues Xcode reports.

## TestFlight Testing Model

- Internal testers can usually test first after the build finishes processing.
- External testers require beta review before a public TestFlight link is active.
- If the app is not ready for broad testing, keep it to internal testers only.

## How To Invite Friends

1. Add their Apple IDs as testers in App Store Connect.
2. Confirm they are assigned to the correct test group.
3. Share the TestFlight invitation link or let them install through the TestFlight app.
4. Ask them to test the flows listed in the release checklist before wider rollout.

## What Friends Should Test

- Quick Add
- Parse Text
- Goals
- Widgets
- Share Extension
- PDF export
- Local notifications
- Back Tap shortcut to Quick Add

## If Signing Fails

- Confirm the app is attached to the correct team.
- Confirm the app group identifier exists in the Apple Developer portal.
- Re-check the widget and share extension signing settings.
- Re-run `xcodegen generate` if `project.yml` changed.
- Verify the bundle identifiers were not changed after App Store Connect setup.

## Notes

- Personal Team is fine for local builds but is not enough for TestFlight.
- The app does not require a login or cloud account for core usage.
- Pocket Leak remains privacy-safe: no automatic reading of bank notifications.
