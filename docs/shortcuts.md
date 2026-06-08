# Shortcuts And Back Tap

Pocket Leak does not read system notifications directly. The supported Shortcut flow is to open the app quickly, then paste or type the transaction text yourself if you want parsing help.

## Supported Shortcut Flow

- App URL schemes: `jtap://` and `pocketleak://`
- Quick Add route: `pocketleak://quick-add`
- Dashboard route: `pocketleak://dashboard`
- History route: `pocketleak://history`
- Insights route: `pocketleak://insights`
- Goals route: `pocketleak://goals`
- Prefill route: `pocketleak://add?amount=120&merchant=Oxxo&category=food`

## Create A Shortcut

1. Open the iOS Shortcuts app.
2. Create a new shortcut.
3. Add the action for `Open URLs`.
4. Set the URL to `pocketleak://quick-add`.
5. Save the shortcut with a clear name such as `Open Pocket Leak Quick Add`.
6. Optionally test `pocketleak://add?amount=120&merchant=Oxxo&category=food` if you want a prefilled draft.

## Assign It To Back Tap

1. Open iOS Settings.
2. Go to `Accessibility` > `Touch` > `Back Tap`.
3. Choose `Double Tap` or `Triple Tap`.
4. Assign the `Open Pocket Leak Quick Add` shortcut.
5. The exact path is `Settings > Accessibility > Touch > Back Tap > Double Tap > select Shortcut`.
6. If you prefer, assign a separate Shortcut that opens `pocketleak://dashboard`, `pocketleak://history`, or `pocketleak://goals`.

## App Entry Examples

- `pocketleak://quick-add` opens the Quick Add tab.
- `pocketleak://dashboard` opens the Dashboard tab.
- `pocketleak://history` opens the History tab.
- `pocketleak://insights` opens the Insights tab.
- `pocketleak://goals` opens the Goals tab.
- `pocketleak://add?amount=120&merchant=Oxxo&category=food` opens Quick Add and pre-fills fields when possible.

## Limitations

- Back Tap requires the user to configure it manually in iOS Settings.
- The shortcut opens the app; it does not silently read bank notifications.
- Pocket Leak only parses text the user pastes or passes through a Shortcut URL.
- Manual paste parsing is privacy-safe because the user explicitly provides the text.
- No bank integration or cloud sync is included.
- URL prefill is intentionally simple and local-only.
