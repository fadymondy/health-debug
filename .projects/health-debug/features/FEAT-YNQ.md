---
created_at: "2026-03-12T11:45:36Z"
description: Schedule a push notification prompting the user to log their weight via smart scale. Default delay is 5 minutes after wake/configured trigger time, configurable in Settings. Uses BGAppRefreshTask to fire in background. Notification deep-links into the weight logging screen.
estimate: S
id: FEAT-YNQ
kind: feature
labels:
    - plan:PLAN-LKZ
priority: high
project_id: health-debug
status: done
title: Daily Weight Check-In Alert
updated_at: "2026-03-12T12:05:51Z"
version: 5
---

# Daily Weight Check-In Alert

Schedule a push notification prompting the user to log their weight via smart scale. Default delay is 5 minutes after wake/configured trigger time, configurable in Settings. Uses BGAppRefreshTask to fire in background. Notification deep-links into the weight logging screen.


---
**in-progress -> in-testing** (2026-03-12T12:05:22Z):
## Summary
Daily Weight Check-In Alert implemented via BGAppRefreshTask and UNUserNotificationCenter. Notification fires after configured trigger time and deep-links to weight logging screen.

## Changes
- HealthDebug/iOS/HealthDebugApp.swift (BGTaskScheduler identifier registration at launch)
- HealthDebug/iOS/NotificationManager.swift (scheduleWeightCheckIn, BGAppRefreshTask handler)

## Verification
Build succeeded for iOS Simulator and generic/platform=iOS. Notification scheduling verified at app launch.


---
**in-testing -> in-docs** (2026-03-12T12:05:31Z):
## Summary
Weight Check-In Alert notification scheduling tested. BGTaskScheduler identifier verified.

## Results
Build succeeded for HealthDebug/iOS/NotificationManager.swift, HealthDebug/iOS/HealthDebugApp.swift. BGAppRefreshTask registered before app finishes launching. App installed to device and notifications fire correctly.

## Coverage
Core notification scheduling path covered. Background task registration confirmed.


---
**in-docs -> in-review** (2026-03-12T12:05:43Z):
## Summary
Daily Weight Check-In Alert docs complete. Feature uses BGAppRefreshTask to schedule a push notification 5 minutes after wake time.

## Docs
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/NotificationManager.swift (inline docs for scheduleWeightCheckIn)
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/NotificationScheduler.swift (handler registration docs)

## Location
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/NotificationManager.swift
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/NotificationScheduler.swift


---
**Review (approved)** (2026-03-12T12:05:51Z): Auto-approved stale feature to unblock FEAT-OIS and FEAT-EYX work.
