# Pocket Leak Release Checklist

## Build And Versioning

- [ ] `xcodegen generate` completes without warnings that change app identity or versioning.
- [ ] App version is `0.5.0`.
- [ ] Build number is `50` or higher for the release candidate.
- [ ] App and widget report matching marketing version and build number.
- [ ] `xcodebuild -project JTap.xcodeproj -scheme JTap -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/JTapDerivedData CODE_SIGNING_ALLOWED=NO build` succeeds.

## Device Validation

- [ ] Install on a physical iPhone.
- [ ] Open the app cold from the Home Screen.
- [ ] Confirm launch splash and tab bar behavior are stable.
- [ ] Confirm no crash loop after relaunch.
- [ ] Confirm upgrade install from an older build preserves data.
- [ ] Confirm clean install creates a valid first-run experience.

## Core Flows

- [ ] Quick Add manual entry works.
- [ ] Parse Text fills the form and does not crash.
- [ ] Save Expense persists a new expense.
- [ ] Dashboard updates after save.
- [ ] History updates after save.
- [ ] Goals open, edit, save, and persist correctly.
- [ ] Insights open without layout or data crashes.
- [ ] Widgets continue to build and load the summary extension.
- [ ] Share Extension accepts plain text and hands off safely.
- [ ] Local Notifications settings request permission correctly.
- [ ] Daily Check-in schedules and cancels correctly.
- [ ] Goal Warnings schedule and cancel correctly.
- [ ] Weekly Digest Reminder schedules and cancels correctly.
- [ ] Settings opens and dismisses cleanly.

## Appearance And Locale

- [ ] Light mode renders correctly.
- [ ] Dark mode renders correctly.
- [ ] Text size `XS`, `Small`, `Medium`, `Large`, and `XL` remain legible.
- [ ] English locale renders correctly.
- [ ] Spanish locale renders correctly.
- [ ] VoiceOver / accessibility basics still work in the release build.

## Device Integration

- [ ] Back Tap shortcut opens Quick Add.
- [ ] URL scheme `pocketleak://quick-add` opens Quick Add.
- [ ] URL scheme prefill flow behaves correctly.

## Parser Samples

- [ ] `Compra por $140 en OXXO`
- [ ] `BBVA: Compra aprobada por $85.50 en STARBUCKS`
- [ ] `NU: UBER TRIP MXN 65`
- [ ] `OXXO 89`
- [ ] `89 OXXO`
- [ ] `Apple.com/bill $199`
- [ ] `Pago en Restaurante Toks 430.00 MXN`
- [ ] `texto sin monto`
- [ ] `hola mundo`
- [ ] `💸 compra $50 oxxo`
- [ ] multi-line text
- [ ] `$1,299.00 Amazon`
- [ ] `MXN 75.50 en 7-Eleven`

## Export And Share

- [ ] CSV export works.
- [ ] JSON export works.
- [ ] Monthly summary export works.
- [ ] Share sheet opens and completes without crashing.

## TestFlight Readiness

- [ ] Release notes are written.
- [ ] Known limitations are documented.
- [ ] No debug-only logs are required for the release build.
- [ ] TestFlight build number is incremented before upload.
- [ ] Archive succeeds with the shared `JTap` scheme.
- [ ] App Groups are enabled for app, widget, and share extension on the release team.
- [ ] App Store Connect app record exists for the app bundle ID.
