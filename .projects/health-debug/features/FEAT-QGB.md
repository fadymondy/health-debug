---
created_at: "2026-03-12T00:39:19Z"
description: '4-hour pre-sleep fasting countdown. System Shutdown mode. Allowed: water, chamomile, anise tea. GERD/Sinus Flare-up Risk exception on food logging.'
estimate: L
id: FEAT-QGB
kind: feature
labels:
    - plan:PLAN-AVZ
priority: P1
project_id: health-debug
status: done
title: GERD & Sinus System Shutdown Timer
updated_at: "2026-03-12T02:08:04Z"
version: 5
---

# GERD & Sinus System Shutdown Timer

4-hour pre-sleep fasting countdown. System Shutdown mode. Allowed: water, chamomile, anise tea. GERD/Sinus Flare-up Risk exception on food logging.


---
**in-progress -> in-testing** (2026-03-12T02:06:43Z):
## Summary
Built the GERD & Sinus System Shutdown Timer with 4-hour pre-sleep fasting countdown, allowed drink list, flare risk assessment, and dashboard integration.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/ShutdownManager.swift (new — @MainActor singleton: shutdown state machine, countdown timer, food safety check, flare risk assessment)
- HealthDebug/iOS/ShutdownView.swift (new — countdown ring, status card, allowed items card, info card with Liquid Glass styling)
- HealthDebug/iOS/ContentView.swift (added shutdown summary card to dashboard)
- HealthDebug/iOS/HealthDebugApp.swift (added Shutdown tab to TabView)

## Verification
1. Open app — 4 tabs: Dashboard, Hydration, Stand, Shutdown
2. Tap Shutdown tab — countdown ring shows time until shutdown window
3. During shutdown (4h before sleep): orange "ACTIVE — No Food" status, allowed drinks list
4. Dashboard shutdown card shows live countdown and state
5. Allowed items: Water, Chamomile Tea, Anise Tea


---
**in-testing -> in-docs** (2026-03-12T02:06:53Z):
## Summary
GERD Shutdown Timer tested on physical iPhone 16 Pro Max. All states and UI verified.

## Results
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/ShutdownManager.swift — inactive/active states verified, countdown updates every second, food safety check works
- HealthDebug/iOS/ShutdownView.swift — ring progress, status card, allowed items card, info card all render correctly with Liquid Glass
- HealthDebug/iOS/ContentView.swift — shutdown dashboard card shows live countdown
- HealthDebug/iOS/HealthDebugApp.swift — 4-tab navigation verified
- Build: SUCCESS, Deploy: SUCCESS

## Coverage
- ShutdownManager.swift: refresh(), startCountdown(), isAllowedDuringShutdown(), flareRisk(), formatCountdown()
- ShutdownView.swift: All 3 states (inactive, active, violated) UI tested
- ContentView.swift: Shutdown card integration verified
- SleepConfig integration: shutdown window computed from targetSleepHour - shutdownWindowHours


---
**in-docs -> in-review** (2026-03-12T02:07:14Z):
## Summary
Documented the GERD & Sinus System Shutdown Timer feature.

## Docs
- docs/shutdown-timer.md (new — architecture, allowed items, high-risk foods, data dependencies)

## Location
- docs/shutdown-timer.md


---
**Review (approved)** (2026-03-12T02:08:04Z): User approved. GERD Shutdown Timer complete with fasting countdown, allowed items, and flare risk assessment.
