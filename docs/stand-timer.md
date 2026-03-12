# 90-Minute Pomodoro Stand Timer

## Overview

The Stand Timer implements an insulin sensitivity protocol based on the research that prolonged sitting (>90 minutes) degrades glucose uptake. Every 90 minutes, the app alerts you to take a 3-minute walk break.

## How It Works

1. **Start Timer** — Begins a 90-minute sit countdown
2. **Stand Alert** — When the timer expires, a notification fires and the app shows a "Time to Stand" screen
3. **Walk Session** — Tap "Start Walk" for a 3-minute walk countdown. Each completed walk is logged as a `StandSession`
4. **Auto-Cycle** — After the walk, a new 90-minute cycle starts automatically

## Architecture

### StandTimerManager (`HealthDebugKit/Health/StandTimerManager.swift`)

`@MainActor` singleton managing the timer lifecycle:

- **States**: `idle` → `sitting` → `standAlert` → `walking` → back to `sitting`
- **Local Notifications**: Scheduled via `UNTimeIntervalNotificationTrigger` for 90-min intervals
- **Session Logging**: Completed walks are persisted as `StandSession` records in SwiftData

### StandTimerView (`HealthDebug/iOS/StandTimerView.swift`)

Full-screen timer view with:
- Animated progress ring (changes color per state)
- Glass-styled status cards (Liquid Glass)
- Today's progress counter (target: 6 sessions/day)
- Session history list

### Dashboard Integration (`HealthDebug/iOS/ContentView.swift`)

A summary card on the Dashboard tab shows:
- Current timer state and countdown
- Today's completed sessions vs daily target
- Quick start button when idle

### Navigation (`HealthDebug/iOS/HealthDebugApp.swift`)

TabView with two tabs:
- **Dashboard** — Health metrics + stand timer summary
- **Stand** — Full stand timer interface

## Data Model

`StandSession` (`HealthDebugKit/Models/StandSession.swift`):
- `startTime: Date`
- `durationSeconds: Int` (target: 180 = 3 minutes)
- `completed: Bool`

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| Sit interval | 90 minutes | Time between stand breaks |
| Walk duration | 3 minutes | Minimum walk time |
| Daily target | 6 sessions | Goal for a full work day |
