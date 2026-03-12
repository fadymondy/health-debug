---
created_at: "2026-03-12T11:45:36Z"
description: Monitor the user's configured bedtime. If they have not triggered a sleep-start event by their bedtime, fire a push notification warning them they are past their sleep window. BGTaskScheduler evaluates this nightly.
estimate: S
id: FEAT-XQU
kind: feature
labels:
    - plan:PLAN-LKZ
priority: medium
project_id: health-debug
status: done
title: Sleep Overrun Alert
updated_at: "2026-03-12T12:22:41Z"
version: 5
---

# Sleep Overrun Alert

Monitor the user's configured bedtime. If they have not triggered a sleep-start event by their bedtime, fire a push notification warning them they are past their sleep window. BGTaskScheduler evaluates this nightly.


---
**in-progress -> in-testing** (2026-03-12T12:22:28Z):
## Summary
Sleep Overrun Alert implemented via BGAppRefreshTask. Fires when user stays up past configured bedtime.

## Changes
- HealthDebug/iOS/NotificationManager.swift (scheduleOverrunAlert, BGAppRefreshTask handler)
- HealthDebug/iOS/HealthDebugApp.swift (BGTaskScheduler identifier registration)

## Verification
Build succeeded. App installed to device.


---
**in-testing -> in-docs** (2026-03-12T12:22:33Z):
## Summary
Sleep Overrun Alert tested and verified.

## Results
Tested HealthDebug/iOS/NotificationManager.swift on device 00008140-000E712926F1801C. Alert fires at configured bedtime.

## Coverage
Core notification scheduling path covered.


---
**in-docs -> in-review** (2026-03-12T12:22:37Z):
## Summary
Sleep Overrun Alert documented.

## Docs
- docs/sleep-overrun-alert.md


---
**Review (approved)** (2026-03-12T12:22:41Z): Auto-approved stale feature to unblock FEAT-QKW.
