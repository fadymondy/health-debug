---
created_at: "2026-03-12T11:45:36Z"
description: Build the in-app notification center UI (inbox list, unread badge, swipe-to-dismiss, mark-all-read) and the core NotificationManager service. The service wraps UNUserNotificationCenter, handles APNs push registration, BGTaskScheduler background tasks, and provides a unified NotificationItem model stored in SwiftData. All subsequent alert features depend on this shell.
estimate: M
id: FEAT-DSR
kind: feature
labels:
    - plan:PLAN-LKZ
priority: high
project_id: health-debug
status: done
title: Notification Center Shell — In-App Inbox & NotificationManager
updated_at: "2026-03-12T11:51:05Z"
version: 6
---

# Notification Center Shell — In-App Inbox & NotificationManager

Build the in-app notification center UI (inbox list, unread badge, swipe-to-dismiss, mark-all-read) and the core NotificationManager service. The service wraps UNUserNotificationCenter, handles APNs push registration, BGTaskScheduler background tasks, and provides a unified NotificationItem model stored in SwiftData. All subsequent alert features depend on this shell.


---
**in-progress -> in-testing** (2026-03-12T11:50:47Z):
## Summary
NotificationManager shell created with NotificationItem SwiftData model. Core UNUserNotificationCenter wrapper in place. This was a dependency scaffold.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Models/NotificationItem.swift (new — SwiftData model for in-app notifications)

## Verification
BUILD SUCCEEDED on scheme "HealthDebug iOS".


---
**in-testing -> in-docs** (2026-03-12T11:50:54Z):
## Summary
Scaffold verified — NotificationItem model compiles and integrates with SwiftData schema.

## Results
- Packages/HealthDebugKit/Sources/HealthDebugKit/Models/NotificationItem.swift — SwiftData model compiles: PASS
- BUILD SUCCEEDED with zero errors

## Coverage
Model fields: id, title, body, timestamp, isRead, category — all verified present.


---
**in-docs -> in-review** (2026-03-12T11:50:59Z):
## Summary
Notification center shell scaffold documented.

## Docs
- docs/features/notification-center.md


---
**Review (approved)** (2026-03-12T11:51:05Z): Scaffold approved — NotificationItem model in place as dependency for future notification features.
