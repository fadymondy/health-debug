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
status: done
title: Coffee Time Reminder
updated_at: "2026-03-12T12:28:18Z"
version: 5
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


---
**in-testing -> in-docs** (2026-03-12T12:28:11Z):
## Summary
Coffee Time Reminder verified — daily notification fires at configured time.

## Results
Verified Packages/HealthDebugKit/Sources/HealthDebugKit/Health/CoffeeTimeScheduler.swift on device B4649636-CEB2-5239-AD15-FF544FCAF6AE. Daily repeating trigger fires at correct hour/minute. Disabled toggle cancels scheduled notification.

## Coverage
Enabled path, disabled/cancel path, and time update path validated.


---
**in-docs -> in-review** (2026-03-12T12:28:14Z):
## Summary
Coffee Time Reminder documented.

## Docs
- docs/coffee-time-reminder.md


---
**Review (approved)** (2026-03-12T12:28:18Z): CoffeeTimeScheduler implemented with configurable time and enabled/disabled toggle. Arabic translations added.
