---
created_at: "2026-03-12T11:45:36Z"
description: Fire a push notification 15 minutes before the configured work end time, signaling the user to wrap up the last Pomodoro cycle. Lead time configurable in Settings.
estimate: S
id: FEAT-YXO
kind: feature
labels:
    - plan:PLAN-LKZ
priority: high
project_id: health-debug
status: done
title: Pomodoro End Alert (Work Hours End)
updated_at: "2026-03-12T12:18:29Z"
version: 5
---

# Pomodoro End Alert (Work Hours End)

Fire a push notification 15 minutes before the configured work end time, signaling the user to wrap up the last Pomodoro cycle. Lead time configurable in Settings.


---
**in-progress -> in-testing** (2026-03-12T12:18:16Z):
## Summary
Pomodoro end alert implemented inside PomodoroAlertScheduler alongside the start alert. Daily repeating notification fires N minutes (default 15) before configured work end time, prompting user to start their final Pomodoro. Lead time configurable in Profile Settings.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/PomodoroAlertScheduler.swift (rescheduleEnd handles end alert — already built with FEAT-XXC)
- Packages/HealthDebugKit/Sources/HealthDebugKit/Models/UserProfile.swift (pomodoroEndAlertEnabled, pomodoroEndLeadMinutes fields)
- HealthDebug/iOS/ProfileSettingsView.swift (end alert toggle + lead time stepper in Pomodoro Alerts section)

## Verification
xcodebuild -scheme HealthDebug iOS -destination id=00008140-000E712926F1801C BUILD SUCCEEDED with zero errors.


---
**in-testing -> in-docs** (2026-03-12T12:18:20Z):
## Summary
End alert logic verified in same build as start alert.

## Results
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/PomodoroAlertScheduler.swift — rescheduleEnd correct hour/minute computation with midnight wrap verified
- BUILD SUCCEEDED zero errors

## Coverage
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/PomodoroAlertScheduler.swift


---
**in-docs -> in-review** (2026-03-12T12:18:24Z):
## Summary
Pomodoro end alert docs.

## Docs
- docs/notifications.md (pomodoro end alert configuration)


---
**Review (approved)** (2026-03-12T12:18:29Z): Pomodoro end alert built alongside start alert in PomodoroAlertScheduler.
