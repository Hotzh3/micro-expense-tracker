# Shortcuts And Back Tap

Pocket Leak stays privacy-safe: it does not read system notifications from other apps. The supported fast-entry path is explicit user action through Shortcuts, URL schemes, or manual paste.

## Supported URL Schemes

Both schemes below resolve to the same in-app routes:

- `pocketleak://`
- `jtap://`

## Available Routes

- `pocketleak://quick-add`
- `pocketleak://parse?text=Compra%20por%20%24129%20en%20OXXO`
- `pocketleak://dashboard`
- `pocketleak://history`
- `pocketleak://insights`
- `pocketleak://goals`
- `pocketleak://add?amount=120&merchant=Oxxo&category=food`

The `add` route opens Quick Add and can prefill fields when query parameters are present.
The `parse` route opens Quick Add, places decoded text into the pasted-text area, and runs the local parser so the preview can appear without saving anything automatically.

## Quick Add Behavior

- `quick-add` opens the Quick Add screen.
- `parse?text=...` opens Quick Add, loads the text into the pasted-text area, and parses it locally.
- `add?amount=...&merchant=...&category=...` opens Quick Add and pre-fills the form.
- Prefill is explicit only; Pocket Leak never saves automatically from a URL.
- When a URL arrives, the current draft state is cleared first so stale parser output does not leak into the new entry.

## Build A Shortcut

1. Open the iOS Shortcuts app.
2. Create a new shortcut.
3. Add the `Open URLs` action.
4. Set the URL to `pocketleak://quick-add`.
5. Save the shortcut with a clear name such as `Open Pocket Leak Quick Add`.
6. Optional: create a second shortcut that opens `pocketleak://add?amount=120&merchant=Oxxo&category=food` to test prefilled capture.
7. Optional: create a third shortcut that opens `pocketleak://parse?text=Compra%20por%20%24129%20en%20OXXO` to test text handoff.

## Back Tap Setup

1. Open `Settings` on the iPhone.
2. Go to `Accessibility` > `Touch` > `Back Tap`.
3. Choose `Double Tap`.
4. Select the Shortcut you created in Shortcuts.
5. For the fastest flow, use the shortcut that opens `pocketleak://quick-add`.
6. If you want a prefilled route, assign a separate shortcut to the `add` URL example above.
7. If you want a text handoff route, assign a separate shortcut to the `parse` URL example above.

## Shortcut-Friendly Text Intake

You can make a shortcut that starts from copied text or a Share Sheet handoff and then opens Pocket Leak:

1. Receive text in the shortcut.
2. Build a URL such as `pocketleak://add?amount=129&merchant=OXXO&category=food`.
3. Open that URL.
4. Review the draft in Quick Add and tap `Save Expense` only when the details are correct.

For manual workflows, copy the bank text from a notification, open Pocket Leak, paste it into Quick Add, and tap `Parse Text`.

## Examples

- `pocketleak://quick-add`
- `jtap://quick-add`
- `pocketleak://dashboard`
- `pocketleak://history`
- `pocketleak://insights`
- `pocketleak://goals`
- `pocketleak://add?amount=120&merchant=Oxxo&category=food`
- `pocketleak://add?amount=129.00&merchant=Starbucks%20Coffee&category=food`
- `pocketleak://parse?text=Compra%20por%20%24129%20en%20OXXO`
- `pocketleak://parse?text=BBVA%3A%20Compra%20aprobada%20por%20%2485.50%20en%20STARBUCKS`

## Limitations

- iOS does not let Pocket Leak detect Back Tap directly inside the app.
- Back Tap must be configured manually by the user.
- Pocket Leak does not read notifications from BBVA, Nu, Mercado Pago, or other apps.
- The app only handles text that the user explicitly passes through Shortcuts, the clipboard, or paste actions.
- URL prefill is local-only and does not auto-save.
- Clipboard intake happens only after an explicit tap in the app.

## Troubleshooting

- If the shortcut does nothing, confirm the URL uses `pocketleak://` or `jtap://` and not a web URL.
- If Back Tap does not trigger, re-check `Settings` > `Accessibility` > `Touch` > `Back Tap` and make sure the shortcut is assigned to `Double Tap`.
- If Quick Add opens with stale fields, close the app, relaunch it, and try the route again.
- If percent-encoded merchant names look wrong, make sure the Shortcut is opening the full URL and not stripping query parameters.
- If the route opens the app but not the target tab, use the exact path `pocketleak://quick-add`.
