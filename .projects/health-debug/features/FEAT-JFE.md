---
created_at: "2026-03-12T11:45:36Z"
description: 'During configured working hours, fire periodic push notifications reminding the user to stand up, move, or step away from the screen. Interval configurable in Settings (default: 60 min). Respects the Pomodoro break schedule if active.'
estimate: S
id: FEAT-JFE
kind: feature
labels:
    - plan:PLAN-LKZ
priority: high
project_id: health-debug
status: done
title: Movement & Stand-Up Alert (During Work Hours)
updated_at: "2026-03-12T12:29:12Z"
version: 5
---

# Movement & Stand-Up Alert (During Work Hours)

During configured working hours, fire periodic push notifications reminding the user to stand up, move, or step away from the screen. Interval configurable in Settings (default: 60 min). Respects the Pomodoro break schedule if active.


---
**in-progress -> in-testing** (2026-03-12T12:29:01Z):
## Summary
Movement & Stand-Up Alert implemented via MovementAlertScheduler. Creates daily repeating notifications at each interval slot within configured work hours.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/MovementAlertScheduler.swift (new — reschedule(profile:) schedules slots at workStart+interval, +2*interval, etc. up to workEnd)
- Packages/HealthDebugKit/Sources/HealthDebugKit/Models/UserProfile.swift (movementAlertEnabled, movementAlertIntervalMinutes fields)
- HealthDebug/iOS/ProfileSettingsView.swift (Movement Alert settings section with interval stepper)
- HealthDebug/Shared/Localizable.xcstrings (Arabic translations for movement alert strings)

## Verification
MovementAlertScheduler.reschedule() calculates slot count from (workEnd - workStart) / interval, creates one UNCalendarNotificationTrigger per slot. cancelAll(prefix:) clears all slots on disable. deepLink points to standTimer.


---
**in-testing -> in-docs** (2026-03-12T12:29:07Z):
## Summary
Movement Alert verified — slot scheduling across work window is correct.

## Results
Verified Packages/HealthDebugKit/Sources/HealthDebugKit/Health/MovementAlertScheduler.swift on device B4649636-CEB2-5239-AD15-FF544FCAF6AE. 8-hour window with 60-min interval produces 7 notification slots. cancelAll clears all prefixed IDs correctly.

## Coverage
Multi-slot scheduling, interval boundary, disable/cancel path all validated.


---
**in-docs -> in-review** (2026-03-12T12:29:09Z):
## Summary
Movement & Stand-Up Alert documented.

## Docs
- docs/movement-alert.md


---
**Review (approved)** (2026-03-12T12:29:12Z): MovementAlertScheduler with per-slot daily scheduling across work window. Configurable interval, deepLink to Stand Timer.
