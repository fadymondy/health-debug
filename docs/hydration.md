# Hydration & Gout Protocol Engine

## Overview

Smart hydration tracking with a 2.5L daily goal distributed evenly across a 10-hour work window. Includes uric acid flush tracking for gout prevention and dehydration warnings based on schedule adherence.

## How It Works

1. **Quick Log** — Tap a button to log 150ml (small), 250ml (glass), or 500ml (bottle)
2. **Smart Schedule** — The app calculates expected intake based on your work window (9am-7pm default) and shows your deficit
3. **Status Tracking** — On Track / Slightly Behind / Dehydrated / Goal Reached
4. **Gout Protocol** — Tracks water intake against the flush target; adequate hydration helps clear uric acid crystals from joints

## Architecture

### HydrationManager (`HealthDebugKit/Health/HydrationManager.swift`)

`@MainActor` singleton managing:

- **Water logging** via SwiftData (`WaterLog` model)
- **Schedule calculation** — linear distribution across work window
- **Deficit tracking** — how far behind the expected intake
- **Status classification** — based on deficit thresholds (250ml, 500ml)
- **Gout flush** — remaining glasses to hit daily target
- **Next drink timing** — minutes until the next glass should be consumed

### HydrationView (`HealthDebug/iOS/HydrationView.swift`)

Full-screen hydration tracker:
- Water ring with angular gradient progress
- Quick-log buttons (150/250/500ml) in `GlassEffectContainer`
- Schedule card with expected vs actual intake
- Gout protocol card with flush progress bar
- Today's log history

### Dashboard Integration (`HealthDebug/iOS/ContentView.swift`)

Summary card showing:
- Current intake vs daily goal with progress bar
- Status badge (color-coded)

## Data Model

`WaterLog` (`HealthDebugKit/Models/WaterLog.swift`):
- `amount: Int` (milliliters)
- `timestamp: Date`
- `source: String` ("ios", "watch", "menubar")

`UserProfile` fields used:
- `dailyWaterGoalMl: Int` (default: 2500)
- `workStartHour/Minute`, `workEndHour/Minute` (work window)

## Status Thresholds

| Status | Deficit |
|--------|---------|
| On Track | <= 250ml |
| Slightly Behind | 250-500ml |
| Dehydrated | > 500ml |
| Goal Reached | Total >= goal |
