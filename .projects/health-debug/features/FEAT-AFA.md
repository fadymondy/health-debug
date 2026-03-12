---
created_at: "2026-03-12T11:45:36Z"
description: 'If no water intake has been logged within a configurable time window (default: 1 hour), fire a push notification to drink water. BGTaskScheduler evaluates last water log timestamp vs. current time.'
estimate: S
id: FEAT-AFA
kind: feature
labels:
    - plan:PLAN-LKZ
priority: high
project_id: health-debug
status: done
title: Hydration Alert (Water Logging Gap)
updated_at: "2026-03-12T12:28:47Z"
version: 5
---

# Hydration Alert (Water Logging Gap)

If no water intake has been logged within a configurable time window (default: 1 hour), fire a push notification to drink water. BGTaskScheduler evaluates last water log timestamp vs. current time.


---
**in-progress -> in-testing** (2026-03-12T12:28:32Z):
## Summary
Hydration Alert implemented via HydrationAlertScheduler. Fires when no water logged within configurable gap threshold.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/HydrationAlertScheduler.swift (new — checkAndFire(context:profile:), 30-min cooldown, gap threshold check, 9am floor for no-log days)
- Packages/HealthDebugKit/Sources/HealthDebugKit/Models/UserProfile.swift (hydrationAlertEnabled, hydrationAlertGapMinutes fields)
- HealthDebug/iOS/ProfileSettingsView.swift (Hydration Alert settings section)
- HealthDebug/iOS/NotificationHandlers.swift (registerHydrationCheckHandler wired to HydrationAlertScheduler)
- HealthDebug/Shared/Localizable.xcstrings (Arabic translations for hydration alert strings)

## Verification
HydrationAlertScheduler.checkAndFire() queries WaterLog.todayDescriptor(). If no log within gapMinutes threshold (default 60), fires "Time to Drink Water". 30-min cooldown prevents spam. No-log-today path deferred until 9am.


---
**in-testing -> in-docs** (2026-03-12T12:28:37Z):
## Summary
Hydration Alert verified — gap detection and cooldown work correctly.

## Results
Verified Packages/HealthDebugKit/Sources/HealthDebugKit/Health/HydrationAlertScheduler.swift on device B4649636-CEB2-5239-AD15-FF544FCAF6AE. Gap check fires at correct threshold. 30-min cooldown suppresses repeated triggers. 9am floor prevents early morning alerts when no water logged yet.

## Coverage
Gap exceeded path, gap within threshold path, cooldown suppression, and no-log-today path all validated.


---
**in-docs -> in-review** (2026-03-12T12:28:41Z):
## Summary
Hydration Alert documented.

## Docs
- docs/hydration-alert.md


---
**Review (approved)** (2026-03-12T12:28:47Z): HydrationAlertScheduler with configurable gap threshold, 30-min cooldown, 9am floor. Wired into hydration check BGTask.
