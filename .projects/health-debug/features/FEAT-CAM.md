---
created_at: "2026-03-12T11:45:36Z"
description: Scheduled daily push notification at a user-configured coffee time(s). Reminds the user it is coffee time. Configurable time slots and enabled/disabled toggle in Settings.
estimate: S
id: FEAT-CAM
kind: feature
labels:
    - plan:PLAN-LKZ
priority: low
project_id: health-debug
status: in-testing
title: Coffee Time Reminder
updated_at: "2026-03-12T12:28:07Z"
version: 2
---

# Coffee Time Reminder

Scheduled daily push notification at a user-configured coffee time(s). Reminds the user it is coffee time. Configurable time slots and enabled/disabled toggle in Settings.


---
**in-progress -> in-testing** (2026-03-12T12:28:07Z):
## Summary
Coffee Time Reminder implemented via CoffeeTimeScheduler. Daily repeating notification at user-configured hour/minute.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/CoffeeTimeScheduler.swift (new — reschedule(profile:), daily UNCalendarNotificationTrigger at coffeeAlertHour:coffeeAlertMinute)
- Packages/HealthDebugKit/Sources/HealthDebugKit/Models/UserProfile.swift (coffeeAlertEnabled, coffeeAlertHour, coffeeAlertMinute fields)
- HealthDebug/iOS/ProfileSettingsView.swift (Coffee Alert settings section with time picker)
- HealthDebug/Shared/Localizable.xcstrings (Arabic translations for coffee reminder strings)

## Verification
CoffeeTimeScheduler.reschedule() cancels existing alerts and schedules a new daily repeating notification. Disabled toggle cancels all coffee alerts. Time picker in settings updates coffeeAlertHour/Minute and triggers reschedule on save.
