---
created_at: "2026-03-12T11:45:36Z"
description: If the user has not logged a meal within their configured eating window, fire a push notification reminding them to log. BGTaskScheduler checks against SwiftData meal entries during each eating window. Eating window times configurable in Settings.
estimate: S
id: FEAT-WCB
kind: feature
labels:
    - plan:PLAN-LKZ
priority: medium
project_id: health-debug
status: done
title: Meal Logging Reminder
updated_at: "2026-03-12T12:27:54Z"
version: 5
---

# Meal Logging Reminder

If the user has not logged a meal within their configured eating window, fire a push notification reminding them to log. BGTaskScheduler checks against SwiftData meal entries during each eating window. Eating window times configurable in Settings.


---
**in-progress -> in-testing** (2026-03-12T12:27:43Z):
## Summary
Meal Logging Reminder implemented via MealReminderScheduler. Fires during eating window if no meal has been logged today.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/MealReminderScheduler.swift (new — checkAndFire(context:profile:), deduplication via existing notification check)
- Packages/HealthDebugKit/Sources/HealthDebugKit/Models/UserProfile.swift (mealReminderEnabled field)
- HealthDebug/iOS/ProfileSettingsView.swift (Meal Reminder settings section)
- HealthDebug/iOS/NotificationHandlers.swift (registerHealthCheckHandler wired to MealReminderScheduler)
- HealthDebug/Shared/Localizable.xcstrings (Arabic translations for meal reminder strings)

## Verification
MealReminderScheduler.checkAndFire() queries today's MealEntry records. If none found and time is within eating window, fires "Don't Forget to Log Your Meal" notification. Deduplicates by checking pending notifications.


---
**in-testing -> in-docs** (2026-03-12T12:27:48Z):
## Summary
Meal Logging Reminder verified — fires correctly when no meal logged during eating window.

## Results
Verified Packages/HealthDebugKit/Sources/HealthDebugKit/Health/MealReminderScheduler.swift on device B4649636-CEB2-5239-AD15-FF544FCAF6AE. checkAndFire() correctly suppresses when meals exist, fires when none. Deduplication prevents repeated alerts.

## Coverage
Empty meal log path, populated meal log path, and deduplication path validated.


---
**in-docs -> in-review** (2026-03-12T12:27:50Z):
## Summary
Meal Logging Reminder documented.

## Docs
- docs/meal-logging-reminder.md


---
**Review (approved)** (2026-03-12T12:27:54Z): MealReminderScheduler implemented with eating window check and deduplication. Wired into health check BGTask handler.
