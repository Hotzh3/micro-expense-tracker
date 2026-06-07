# Shortcuts And Back Tap

Pocket Leak does not read system notifications directly. The supported Shortcut flow is to open the app quickly, then paste or type the transaction text yourself if you want parsing help.

## Supported Shortcut Flow

- App URL scheme: `jtap://quick-add`
- Optional destinations: `jtap://dashboard`, `jtap://history`, `jtap://insights`

## Create A Shortcut

1. Open the iOS Shortcuts app.
2. Create a new shortcut.
3. Add the action for opening a URL.
4. Set the URL to `jtap://quick-add`.
5. Save the shortcut with a clear name such as `Open Pocket Leak Quick Add`.

## Assign It To Back Tap

1. Open iOS Settings.
2. Go to `Accessibility` > `Touch` > `Back Tap`.
3. Choose `Double Tap` or `Triple Tap`.
4. Assign the `Open Pocket Leak Quick Add` shortcut.
5. The exact path is `Settings > Accessibility > Touch > Back Tap > Double Tap > select Shortcut`.

## Limitations

- Back Tap requires the user to configure it manually in iOS Settings.
- The shortcut opens the app; it does not silently read bank notifications.
- Manual paste parsing is privacy-safe because the user explicitly provides the text.
- No bank integration or cloud sync is included.
