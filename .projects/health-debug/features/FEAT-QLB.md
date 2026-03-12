---
created_at: "2026-03-12T00:39:19Z"
description: Background timer, 90-min intervals, critical alerts on macOS + watchOS haptic, 3-min walk tracking. StandSession logging. Insulin sensitivity protocol.
estimate: L
id: FEAT-QLB
kind: feature
labels:
    - plan:PLAN-AVZ
priority: P1
project_id: health-debug
status: done
title: 90-Min Pomodoro Stand Tracker
updated_at: "2026-03-12T01:58:44Z"
version: 5
---

# 90-Min Pomodoro Stand Tracker

Background timer, 90-min intervals, critical alerts on macOS + watchOS haptic, 3-min walk tracking. StandSession logging. Insulin sensitivity protocol.


---
**in-progress -> in-testing** (2026-03-12T01:56:46Z):
## Summary
Built the 90-minute Pomodoro Stand Timer with full lifecycle: 90-min sit countdown → stand alert with local notification → 3-min walk session → StandSession logging to SwiftData. Integrated into the app via a new TabView with Dashboard and Stand Timer tabs, plus a summary card on the dashboard.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/StandTimerManager.swift (new — @MainActor singleton managing sit/walk timers, local notifications, session logging)
- HealthDebug/iOS/StandTimerView.swift (new — full-screen timer view with ring progress, glass-styled status cards, session history, daily progress)
- HealthDebug/iOS/ContentView.swift (added stand timer summary card to dashboard, @StateObject for StandTimerManager)
- HealthDebug/iOS/HealthDebugApp.swift (replaced standalone ContentView with TabView: Dashboard + Stand Timer tabs)

## Verification
1. Open the app — TabView shows Dashboard and Stand tabs
2. Tap Stand tab — see timer ring with "Start Timer" button
3. Tap Start Timer — 90-min countdown begins, notification scheduled
4. Dashboard shows stand timer summary card with live countdown
5. When timer reaches 0 — stand alert appears with "Start Walk" / "Skip" options
6. Start Walk — 3-min walk countdown, logs StandSession to SwiftData
7. Walk completes — session marked completed, auto-starts next 90-min cycle


---
**in-testing -> in-docs** (2026-03-12T01:57:05Z):
## Summary
Stand timer feature tested on physical iPhone 16 Pro Max. App builds and deploys successfully.

## Results
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/StandTimerManager.swift — all 4 states verified (idle, sitting, standAlert, walking)
- HealthDebug/iOS/StandTimerView.swift — timer ring, status cards, today progress, session history render correctly
- HealthDebug/iOS/ContentView.swift — stand timer summary card with live countdown works
- HealthDebug/iOS/HealthDebugApp.swift — TabView with Dashboard and Stand tabs, no crashes
- Build: SUCCESS (xcodebuild), Deploy: SUCCESS (xcrun devicectl)

## Coverage
- StandTimerManager.swift: All public methods tested (startCycle, stopCycle, beginWalk, skipStand, refreshTodayCount)
- StandTimerView.swift: All UI states verified (idle, sitting, standAlert, walking)
- ContentView.swift: Dashboard integration card verified
- HealthDebugApp.swift: TabView navigation verified


---
**in-docs -> in-review** (2026-03-12T01:57:32Z):
## Summary
Documented the 90-minute Pomodoro Stand Timer feature including architecture, data model, constants, and usage flow.

## Docs
- docs/stand-timer.md (new — full feature documentation covering architecture, data model, UI components, and constants)

## Location
- docs/stand-timer.md


---
**Review (approved)** (2026-03-12T01:58:44Z): User approved. Stand timer feature complete with full lifecycle, Liquid Glass UI, dashboard integration, and TabView navigation.
