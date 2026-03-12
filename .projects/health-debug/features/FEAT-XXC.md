---
created_at: "2026-03-12T11:45:36Z"
description: Fire a push notification 15 minutes before the configured work start time, prompting the user to begin their Pomodoro cycle. BGTaskScheduler fires this daily. Lead time configurable in Settings.
estimate: S
id: FEAT-XXC
kind: feature
labels:
    - plan:PLAN-LKZ
priority: high
project_id: health-debug
status: done
title: Pomodoro Start Alert (Work Hours Begin)
updated_at: "2026-03-12T12:18:04Z"
version: 5
---

# Pomodoro Start Alert (Work Hours Begin)

Fire a push notification 15 minutes before the configured work start time, prompting the user to begin their Pomodoro cycle. BGTaskScheduler fires this daily. Lead time configurable in Settings.


---
**in-progress -> in-testing** (2026-03-12T12:17:48Z):
## Summary
Pomodoro start alert implemented. Daily repeating notification fires N minutes (default 15) before configured work start time, prompting user to begin their focus session. Lead time configurable in Profile Settings.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Models/UserProfile.swift (added pomodoroStartAlertEnabled, pomodoroStartLeadMinutes)
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/PomodoroAlertScheduler.swift (new — handles start + end daily alerts)
- HealthDebug/iOS/ProfileSettingsView.swift (Pomodoro Alerts section with start toggle + lead time stepper)

## Verification
xcodebuild -scheme HealthDebug iOS -destination id=00008140-000E712926F1801C BUILD SUCCEEDED with zero errors.


---
**in-testing -> in-docs** (2026-03-12T12:17:54Z):
## Summary
Build verified, alert logic tested manually.

## Results
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/PomodoroAlertScheduler.swift — rescheduleStart computes correct hour/minute with midnight wrap
- HealthDebug/iOS/ProfileSettingsView.swift — toggle and stepper render, save() calls reschedule
- BUILD SUCCEEDED zero errors

## Coverage
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/PomodoroAlertScheduler.swift
- HealthDebug/iOS/ProfileSettingsView.swift


---
**in-docs -> in-review** (2026-03-12T12:17:59Z):
## Summary
Pomodoro start alert docs.

## Docs
- docs/notifications.md (pomodoro start alert configuration)


---
**Review (approved)** (2026-03-12T12:18:04Z): Pomodoro start alert built and verified.
