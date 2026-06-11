# Xcode Setup

This repository is configured to generate the Xcode project reproducibly with XcodeGen.

## Before You Start

- You need a Mac with Xcode installed.
- You need XcodeGen installed locally.
- You need the repository cloned on your machine.

## Install Xcode

1. Install Xcode from the Mac App Store or Apple Developer downloads.
2. Open Xcode once so it can finish installing components.
3. Accept any license prompts if Xcode shows them.

## Install XcodeGen

1. Install Homebrew if you do not already have it.
2. Install XcodeGen:
   - `brew install xcodegen`
3. Verify the install if needed:
   - `xcodegen version`

## Clone And Generate

1. Clone the repository locally.
2. From the repo root, run:
   - `xcodegen generate`
3. Open the generated project:
   - `open JTap.xcodeproj`

## Run In Simulator

1. Select the `JTap` scheme.
2. Choose an iPhone simulator destination.
3. Build and run from Xcode.
4. Use the simulator for UI checks, screenshots, and quick local validation.

## Run On Your Own iPhone

1. Connect the iPhone to your Mac with a cable.
2. Unlock the iPhone.
3. Trust the Mac on the device if prompted.
4. Open `JTap.xcodeproj` in Xcode.
5. Select the physical iPhone as the run destination.
6. Pick a development team in Signing & Capabilities.
7. Build and run from Xcode.

## Expected Result

After running XcodeGen, the app should build as a SwiftUI iPhone app with local persistence, history filters, insights, widgets, and a `pocketleak://` URL scheme for shortcut-style opening. The user-facing app name in the UI should read Pocket Leak.

## Related Guides

- [`docs/free_distribution_guide.md`](free_distribution_guide.md)
- [`docs/iphone_testing.md`](iphone_testing.md)
