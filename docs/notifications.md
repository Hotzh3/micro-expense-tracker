# Local Notifications

Pocket Leak uses only local `UserNotifications` scheduled by the app itself.

## Privacy Rules

- The app does not read notifications from banks or any other apps.
- No push notifications are used.
- All reminders are generated locally on device.
- If notification permission is denied, Pocket Leak will not schedule reminders.

## Notification Types

- Daily Check-in
- Goal Warnings
- Weekly Digest Reminder

## How To Test On iPhone

1. Open Pocket Leak.
2. Go to `Settings`.
3. Enable `Local Notifications`.
4. Allow permission when iOS prompts.
5. Turn on `Daily Check-in`.
6. Turn on `Goal Warnings`.
7. Create a weekly or monthly goal.
8. Save a few expenses so the goal gets close to the limit.
9. Confirm the app stays stable and the local alert appears.
10. Enable `Weekly Digest Reminder` and pick a weekday/time.

## Permission Notes

- Permission is requested only when the user turns notifications on.
- If permission is denied, Pocket Leak shows a local feedback message and offers a route to iOS Settings.
- You can change permission later in `Settings > Notifications` for Pocket Leak.
