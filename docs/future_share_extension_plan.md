# Share Extension Notes

Pocket Leak now includes a minimal Share Extension for explicit user-shared text. The notes below remain useful for understanding the constraints and the privacy-safe implementation choices.

## Why It Was Deferred

- A Share Extension adds another target, more XcodeGen wiring, and extra validation surface.
- This phase was intentionally focused on safe text intake through explicit tap, clipboard, and Shortcuts URL handoff.
- The app already had a local-first parser flow, so the low-risk path was to refine that before expanding into an extension.

## Implemented Scope

- Accept `text/plain`
- Preserve privacy by only receiving user-shared content
- Pass the text into the main app through a local app-group or URL-based handoff
- Land on Quick Add with the pasted text ready for manual parsing

## Implementation Notes

- The extension stays tiny: capture text, hand it off, and exit.
- The main app owns parsing and never saves automatically from the share handoff.
- The App Group identifier must match the widget and the share extension.

## Remaining Risks

- Extension configuration can increase project complexity.
- App-group setup may still require manual Apple Developer capability work for a Personal Team. If XcodeGen cannot enable it automatically, turn on App Groups manually for both the app and extension targets using the same group identifier.
- If signing is fragile, keep the extension minimal and avoid extra logic in the share target.
