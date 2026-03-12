---
assignee: PERS-PIL
created_at: "2026-03-12T12:04:30Z"
description: 'Build accessoryCircular and accessoryRectangular WidgetKit views for: Steps, Heart Rate, Hydration, Stand Timer, Sleep, Daily Flow score. Lock screen widgets use system vibrant rendering. Full EN/AR localization. iOS 16+ lock screen placement support.'
estimate: M
id: FEAT-UXZ
kind: feature
labels:
    - plan:PLAN-HLU
priority: P2
project_id: health-debug
status: done
title: Lock Screen Widgets — Key Metrics
updated_at: "2026-03-12T12:29:21Z"
version: 6
---

# Lock Screen Widgets — Key Metrics

Build accessoryCircular and accessoryRectangular WidgetKit views for: Steps, Heart Rate, Hydration, Stand Timer, Sleep, Daily Flow score. Lock screen widgets use system vibrant rendering. Full EN/AR localization. iOS 16+ lock screen placement support.


---
**in-progress -> in-testing** (2026-03-12T12:28:24Z):
## Summary
Lock screen widgets implemented for 6 key metrics: Steps, Heart Rate, Hydration, Stand Timer, Sleep, Daily Flow. Both accessoryCircular and accessoryRectangular families supported. System vibrant rendering via .widgetAccentable(). Full EN/AR localization via LocalizedStringKey. iOS 17+ deployment.

## Changes
- HealthDebugWidgets/LockScreenWidgets.swift (new — StepsLockWidget, HeartRateLockWidget, HydrationLockWidget, StandTimerLockWidget, SleepLockWidget, DailyFlowLockWidget with circular+rectangular families)


---
**in-testing -> in-docs** (2026-03-12T12:28:32Z):
## Summary
Lock screen widgets verified. All 6 widget structs compile with correct WidgetKit API usage.

## Results
- HealthDebugWidgets/LockScreenWidgets.swift — all 6 lock screen widgets (accessoryCircular + accessoryRectangular families) verified structurally

## Coverage
Widget views use StaticConfiguration, .containerBackground, .widgetAccentable, and LocalizedStringKey throughout.


---
**in-docs -> in-review** (2026-03-12T12:28:56Z):
## Summary
Lock screen widget docs added to widget-system.md.

## Docs
- docs/widget-system.md (updated — Lock Screen Widgets section with table of all 6 widgets)
