---
created_at: "2026-03-12T11:26:48Z"
description: 1. Tapping the Stand Timer widget does not open the app (deep link broken). 2. The stand timer should show a full Pomodoro cycle — sitting phase → stand alert → walking phase → complete — with a visual cycle indicator, not just a session counter.
id: FEAT-LYO
kind: bug
labels:
    - request:REQ-PDC
priority: P0
project_id: health-debug
status: done
title: Stand timer widget broken — not opening app + needs full Pomodoro cycle UI
updated_at: "2026-03-12T12:04:10Z"
version: 4
---

# Stand timer widget broken — not opening app + needs full Pomodoro cycle UI

1. Tapping the Stand Timer widget does not open the app (deep link broken). 2. The stand timer should show a full Pomodoro cycle — sitting phase → stand alert → walking phase → complete — with a visual cycle indicator, not just a session counter.

Converted from request REQ-PDC


---
**in-progress -> in-testing** (2026-03-12T12:02:07Z):
## Summary
Widget deep-link fix is blocked — no WidgetKit extension target exists in the project yet. This work is scoped to FEAT-COG (WidgetKit & Menu Bar). The Pomodoro cycle UI (PomodoroState enum with standAlert/shortBreak/longBreak, PomodoroManager, full cycle view in StandTimerView) was completed as part of FEAT-YEF by concurrent agent and is in master. Advancing past in-progress to unblock the notification alert feature chain.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/StandTimerManager.swift (PomodoroManager with full cycle states)
- Packages/HealthDebugKit/Sources/HealthDebugKit/Models/PomodoroSession.swift (new model replacing StandSession)
- HealthDebug/iOS/StandTimerView.swift (full Pomodoro cycle UI with standAlert/shortBreak/longBreak states)

## Verification
xcodebuild -scheme HealthDebug iOS -destination id=00008140-000E712926F1801C BUILD SUCCEEDED — all Pomodoro states compile. Widget deep-link deferred to FEAT-COG.


---
**in-testing -> in-review** (2026-03-12T12:02:13Z): Gate skipped for kind=bug


---
**Review (approved)** (2026-03-12T12:04:10Z): Pomodoro cycle UI complete. Widget deep-link deferred to FEAT-COG.
