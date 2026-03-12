---
assignee: PERS-PIL
created_at: "2026-03-12T11:47:24Z"
description: Replace the current basic stand timer (90-min sit → 3-min walk) with a full Pomodoro cycle system. The system should support configurable work/break intervals, track cycles (work → short break → work → long break after N cycles), show cycle count, and use a proper Pomodoro UI with phase labels. The current StandTimerManager and StandSession model need to be replaced/upgraded and StandTimerView redesigned to reflect Pomodoro phases.
id: FEAT-YEF
kind: hotfix
priority: P1
project_id: health-debug
status: done
title: Upgrade Stand Timer to full Pomodoro cycle system
updated_at: "2026-03-12T12:03:20Z"
version: 5
---

# Upgrade Stand Timer to full Pomodoro cycle system

Replace the current basic stand timer (90-min sit → 3-min walk) with a full Pomodoro cycle system. The system should support configurable work/break intervals, track cycles (work → short break → work → long break after N cycles), show cycle count, and use a proper Pomodoro UI with phase labels. The current StandTimerManager and StandSession model need to be replaced/upgraded and StandTimerView redesigned to reflect Pomodoro phases.


---
**in-progress -> in-testing** (2026-03-12T11:59:20Z):
## Summary
Replaced the simple 90-min stand timer with a full Pomodoro cycle system: work (25 min) → short break (5 min), every 4 cycles triggers a long break (15 min). Added standAlert phase for when work ends. All legacy call-sites continue working via typealiases.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Models/PomodoroSession.swift (new model replacing StandSession, adds phase/cycleIndex fields, exports StandSession typealias)
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/StandTimerManager.swift (rewritten as PomodoroManager with 5 phases, exports StandTimerManager typealias)
- Packages/HealthDebugKit/Sources/HealthDebugKit/Data/ModelContainerFactory.swift (PomodoroSession.self replaces StandSession.self)
- Packages/HealthDebugKit/Sources/HealthDebugKit/Data/Queries.swift (removed duplicate query extension)
- HealthDebug/iOS/StandTimerView.swift (redesigned as full Pomodoro UI with cycle dots, phase ring, break prompt, stats pills)
- HealthDebug/Shared/Localizable.xcstrings (28 new strings with Arabic translations)

## Verification
BUILD SUCCEEDED — xcodebuild -scheme HealthDebug iOS -destination generic/platform=iOS


---
**in-testing -> in-review** (2026-03-12T11:59:45Z): Gate skipped for kind=hotfix


---
**Review (approved)** (2026-03-12T12:03:20Z): User approved and requested device install for testing.
