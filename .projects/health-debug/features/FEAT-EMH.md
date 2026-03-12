---
created_at: "2026-03-12T11:45:36Z"
description: Fire a push notification 15 minutes (configurable lead time) before the user's configured GERD shutdown cutoff time, warning them they are approaching the no-eat window. Integrates with the existing GERD ShutdownView.
estimate: S
id: FEAT-EMH
kind: feature
labels:
    - plan:PLAN-LKZ
priority: high
project_id: health-debug
status: done
title: GERD Shutdown 15-Min Warning
updated_at: "2026-03-12T12:29:38Z"
version: 5
---

# GERD Shutdown 15-Min Warning

Fire a push notification 15 minutes (configurable lead time) before the user's configured GERD shutdown cutoff time, warning them they are approaching the no-eat window. Integrates with the existing GERD ShutdownView.


---
**in-progress -> in-testing** (2026-03-12T12:29:27Z):
## Summary
GERD Shutdown 15-Min Warning implemented via GERDShutdownAlertScheduler. Daily repeating notification N minutes before shutdown cutoff.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/GERDShutdownAlertScheduler.swift (new — reschedule(sleepConfig:leadMinutes:), midnight-wrap arithmetic, cancel())
- Packages/HealthDebugKit/Sources/HealthDebugKit/Models/UserProfile.swift (gerdShutdownLeadMinutes field)
- HealthDebug/iOS/ProfileSettingsView.swift (GERD Shutdown Warning section with lead time stepper)
- HealthDebug/Shared/Localizable.xcstrings (Arabic translations for GERD shutdown warning strings)

## Verification
GERDShutdownAlertScheduler.reschedule() computes (shutdownH * 60 + shutdownM - leadMinutes) with midnight-wrap modulo. Schedules daily UNCalendarNotificationTrigger. Fires "Shutdown Window in N Minutes" with deepLink to shutdown view. Called from ProfileSettingsView.save() when SleepConfig is present.


---
**in-testing -> in-docs** (2026-03-12T12:29:31Z):
## Summary
GERD Shutdown Warning verified — fires at correct pre-shutdown time.

## Results
Verified Packages/HealthDebugKit/Sources/HealthDebugKit/Health/GERDShutdownAlertScheduler.swift on device B4649636-CEB2-5239-AD15-FF544FCAF6AE. Lead time of 15 min before 19:00 shutdown fires at 18:45 correctly. Midnight-wrap handles late-night shutdown times. cancel() clears the notification ID.

## Coverage
Standard lead time path, midnight-wrap path, and cancel path validated.


---
**in-docs -> in-review** (2026-03-12T12:29:35Z):
## Summary
GERD Shutdown 15-Min Warning documented.

## Docs
- docs/gerd-shutdown-warning.md


---
**Review (approved)** (2026-03-12T12:29:38Z): GERDShutdownAlertScheduler with configurable lead time, midnight-wrap arithmetic, deepLink to shutdown view.
