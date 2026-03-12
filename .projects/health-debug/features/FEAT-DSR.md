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
status: in-progress
title: Notification Center Shell — In-App Inbox & NotificationManager
updated_at: "2026-03-12T11:46:59Z"
version: 2
---

# Notification Center Shell — In-App Inbox & NotificationManager

Build the in-app notification center UI (inbox list, unread badge, swipe-to-dismiss, mark-all-read) and the core NotificationManager service. The service wraps UNUserNotificationCenter, handles APNs push registration, BGTaskScheduler background tasks, and provides a unified NotificationItem model stored in SwiftData. All subsequent alert features depend on this shell.
