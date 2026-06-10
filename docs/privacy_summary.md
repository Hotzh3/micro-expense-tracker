# Privacy Summary

Pocket Leak is designed as a local-first personal finance app.

## What Stays On Device

- Expenses
- Categories
- Spending goals
- Insights generated from local expense data
- Widget summary state
- Local notification preferences
- Export files created by the user

## What The App Does Not Do

- No data sale
- No third-party tracking for core functionality
- No cloud sync for expenses
- No automatic reading of bank notifications
- No background scraping of system notifications
- No automatic clipboard polling
- No push notification backend
- No remote analytics required for basic usage

## Text Parsing

- Parsing is local.
- The parser only runs on text the user pastes or explicitly shares.
- The app does not try to infer spending from other apps without a user action.
- If the user shares text through the iOS Share Sheet or pastes text manually, Pocket Leak may extract amount, merchant, and category to help the user enter an expense faster.

## Widgets

- Widgets read a local summary of spending data.
- Widgets do not transmit user data off device.
- Widget state is limited to display-only summary data.

## Share Extension

- The Share Extension only receives text that the user explicitly shares.
- It does not read notifications.
- It does not inspect other apps without a user action.
- Shared text is kept local and handed off to Pocket Leak through the app group or URL flow.

## Local Notifications

- Notifications are generated locally by Pocket Leak.
- They are used for reminders such as daily check-in, goal warnings, and weekly digest reminders.
- Pocket Leak does not use push notifications for this workflow.

## Export

- CSV, JSON, and PDF exports are generated on device.
- Export files are only shared if the user chooses a destination through the system share sheet.

## Public Privacy Position

Pocket Leak stores expenses locally and only parses text the user provides explicitly.

Suggested App Store privacy note:

- Data is used only to provide personal finance tracking and reminders.
- No data is sold.
- No tracking is required for core product use.
- The user controls what text is shared or pasted into the app.
