# Common Xcode Errors

## No Signing Certificate

Usually means the selected team does not have a valid development certificate yet.

What to try:

- re-select the team in Signing & Capabilities
- keep automatic signing enabled
- sign in to the correct Apple ID

## Bundle Identifier Already Used

The bundle ID may already belong to another app record or another target is using the same ID.

What to try:

- confirm the app, widget, and share extension use the intended identifiers
- regenerate the project if `project.yml` changed
- make sure you are not mixing another repo's signing settings

## App Group Not Available

The widget or share extension may need the App Group capability to be available in the signing team.

What to try:

- confirm the App Group identifier exists for the team
- re-open Signing & Capabilities
- rebuild the app and the extensions

## Developer Mode Disabled

Newer iPhones require Developer Mode to install apps from Xcode.

What to try:

- enable Developer Mode in Settings
- restart the device if prompted

## Device Locked

Xcode may fail to install if the iPhone is locked.

What to try:

- unlock the iPhone
- keep it unlocked while the install completes

## XcodeGen Not Installed

The project cannot be generated if XcodeGen is missing.

What to try:

- install XcodeGen with Homebrew
- run `xcodegen generate` from the repo root

## DerivedData Issues

Stale build products can cause odd compile or install failures.

What to try:

- delete the DerivedData folder for this project
- regenerate the project
- rebuild from Xcode

## Widgets Not Appearing

Widgets can take time to show after install or need a rebuild after capability changes.

What to try:

- open the main app once
- wait briefly after install
- remove and re-add the widget if needed

## Share Extension Not Appearing

The share extension may not show until the app is installed and the share sheet is reopened.

What to try:

- reinstall the app
- open the iOS share sheet again
- confirm the extension target built successfully

## Quick Reference

If in doubt, delete the app from the device, rebuild from Xcode, and try again with the device unlocked and Developer Mode enabled.

