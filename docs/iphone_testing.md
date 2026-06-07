# iPhone Testing

## Connect The Device

1. Plug the iPhone into your Mac with a USB cable.
2. Unlock the iPhone.
3. Tap `Trust` if the device prompts you to trust the computer.
4. Keep the iPhone unlocked while Xcode finishes pairing.

## Select The Device In Xcode

1. Open `JTap.xcodeproj`.
2. Choose the `JTap` scheme.
3. Open the run destination menu in Xcode.
4. Select the physical iPhone instead of a simulator.

## Run The App

1. Build and run from Xcode.
2. If signing is not configured yet, enable automatic signing for the `JTap` target and use your development team.
3. Wait for the app to install on the iPhone.
4. Launch Pocket Leak on device and confirm the local data flow works as expected.

## Expected Signing Issues

- Xcode may ask you to trust the development certificate on the iPhone.
- A free Apple ID or development account may show provisioning warnings until the team is configured.
- If signing fails, re-select the team and rebuild.

## What To Test On Device

- App launch and dark minimal UI
- Quick Add usability with one hand
- Saving an expense
- Save feedback appearance
- Dashboard totals updating
- History filtering and delete flow
- Insights updating after new entries
- App relaunch preserving stored expenses
- `jtap://quick-add` shortcut invocation

## Local Testing Limits

- This repo does not include bank integrations or live notification scraping.
- The parser only works with text the user pastes in manually.
- Simulator behavior may differ from physical-device behavior for Back Tap and signing.
