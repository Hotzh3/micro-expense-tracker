# Shortcuts

Pocket Leak supports local URL schemes for quick navigation and prefilled capture.

## Schemes

- `pocketleak://`
- `jtap://`

## Routes

- `pocketleak://quick-add`
- `pocketleak://add?amount=120&merchant=Oxxo&category=food`
- `pocketleak://dashboard`
- `pocketleak://history`
- `pocketleak://insights`
- `pocketleak://goals`

## Quick Add

- `quick-add` opens the Quick Add screen.
- `add?amount=...&merchant=...&category=...` opens Quick Add with a prefilled draft.
- Prefill is explicit only. Pocket Leak never saves from a URL automatically.

## Back Tap

See [Back Tap Quick Add](/Users/josema/Documents/micro-expense-tracker/docs/back_tap_shortcut.md) for the step-by-step setup.

## Notes

- If a shortcut opens the app but not the expected screen, use the exact route `pocketleak://quick-add`.
- The Share Extension can still hand text to the app, but the visible Quick Add experience now focuses on manual entry and past-date capture.
