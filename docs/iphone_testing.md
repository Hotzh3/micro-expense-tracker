# iPhone Testing

## Connect The Device

1. Plug the iPhone into your Mac with a USB cable.
2. Unlock the iPhone.
3. Tap `Trust` if the device prompts you to trust the computer.
4. Keep the iPhone unlocked while Xcode finishes pairing.

## Developer Mode

1. On iPhone, open `Settings`.
2. Go to `Privacy & Security`.
3. Turn on `Developer Mode` if iOS asks for it.
4. Restart the iPhone if the system prompts you.

## Select The Device In Xcode

1. Open `JTap.xcodeproj`.
2. Choose the `JTap` scheme.
3. Open the run destination menu in Xcode.
4. Select the physical iPhone instead of a simulator.

## Run The App

1. Build and run from Xcode.
2. If signing is not configured yet, enable automatic signing for the `JTap` target and select your team.
3. Wait for the app to install on the iPhone.
4. Launch Pocket Leak on device and confirm the local data flow works as expected.

## Common Signing Errors

- `No signing certificate` or `No profiles for ... were found`
- bundle identifier already used by another target or account
- device locked during install
- Developer Mode disabled on the iPhone
- Team not selected in Signing & Capabilities

## After Install

1. Open the app once so iOS can register the bundle.
2. If the widget does not appear, wait a moment or restart the device.
3. If the share extension does not appear, reinstall the app and re-open the share sheet.
4. If Xcode says the app is damaged or cannot be verified, delete it and install again.

## What To Test On Device

- App launch and dark minimal UI
- Quick Add usability with one hand
- Saving an expense
- Save feedback appearance
- Dashboard totals updating
- History filtering and delete flow
- Insights updating after new entries
- App relaunch preserving stored expenses
- Widget appearance after install
- Share Extension text handoff
- `jtap://quick-add` shortcut invocation

## Local Testing Limits

- This repo does not include bank integrations or live notification scraping.
- The parser only works with text the user pastes in manually.
- Simulator behavior may differ from physical-device behavior for Back Tap, widgets, and signing.
