# Privacy Summary

Pocket Leak is intentionally local-first.

## Stored On Device

- expenses
- categories
- goals
- category budgets
- recurring expenses
- widget summary state
- notification preferences
- export files the user creates
- demo manifest metadata

## Not Used For Core Functionality

- cloud sync
- login
- third-party tracking
- remote analytics
- automatic bank scraping
- automatic notification reading from other apps
- automatic clipboard polling

## Text Parsing

- parsing only runs when the user pastes or explicitly shares text
- the app does not infer spending from private data in the background
- any merchant or amount extraction happens locally on the device

## Widgets And Share Extension

- widgets read local summary data only
- the share extension only processes text explicitly shared by the user
- neither feature uploads private expense data

## Local Notifications

- notifications are generated locally by Pocket Leak
- reminders cover check-ins, goal warnings, and the weekly digest
- no push backend is required

## Portfolio Positioning

Pocket Leak is a good portfolio project because the privacy story is simple: the app keeps user data local, only parses explicit text input, and avoids the platform limitations that make bank scraping unreliable or invasive.

