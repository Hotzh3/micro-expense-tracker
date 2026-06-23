# Back Tap Quick Add

Pocket Leak supports a local deep link for Quick Add:

- `pocketleak://quick-add`

When that URL opens, the app brings you directly to Quick Add. iOS does not allow a floating Back Tap overlay from another app, so the shortcut simply opens Pocket Leak straight into the capture screen.

## Setup

1. Open the iOS `Shortcuts` app.
2. Create a new shortcut.
3. Add `Open URLs`.
4. Set the URL to `pocketleak://quick-add`.
5. Save the shortcut with a name like `Open Pocket Leak Quick Add`.
6. Open `Settings` on the iPhone.
7. Go to `Accessibility` > `Touch` > `Back Tap`.
8. Choose `Double Tap`.
9. Assign the shortcut you just created.

## Tips

- In Pocket Leak Settings, use `Test Quick Add Link` to verify the route before assigning Back Tap.
- If the app is already open, the deep link reuses the current session and does not require reinstalling or clearing data.
- You can still use `pocketleak://add?amount=120&merchant=Oxxo&category=food` for a prefilled Quick Add draft.
