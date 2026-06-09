# Future Share Extension Plan

Pocket Leak can add a Share Extension later if the product needs a lower-friction way to receive text from other apps.

## Why It Is Deferred

- A Share Extension adds another target, more XcodeGen wiring, and extra validation surface.
- This phase is intentionally focused on safe text intake through explicit tap, clipboard, and Shortcuts URL handoff.
- The app already has a local-first parser flow, so the low-risk path is to refine that before expanding into an extension.

## Proposed Scope

- Accept `text/plain`
- Preserve privacy by only receiving user-shared content
- Pass the text into the main app through a local app-group or URL-based handoff
- Land on Quick Add with the pasted text ready for manual parsing

## Implementation Notes

- Add the extension only if the repo can keep XcodeGen stable and the signing setup remains simple.
- Reuse the existing parser in the main app instead of adding duplicate parsing logic in the extension.
- Keep the extension tiny: capture text, hand it off, and exit.

## Risks

- Extension configuration can increase project complexity.
- App-group setup may require manual Apple Developer capability work.
- If signing is fragile, this should stay a future phase rather than being forced into the current one.

