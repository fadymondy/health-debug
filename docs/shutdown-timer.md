# GERD & Sinus System Shutdown Timer

## Overview

A 4-hour pre-sleep fasting countdown that helps prevent GERD (acid reflux) and sinus inflammation. During the shutdown window, only water and specific herbal teas are allowed.

## How It Works

1. **Normal Mode** — Countdown shows time until shutdown begins
2. **Shutdown Active** — 4 hours before bedtime, food is restricted. Only allowed items: Water, Chamomile Tea, Anise Tea
3. **Flare Risk** — If food is logged during shutdown, the app assesses GERD/Sinus flare-up risk

## Architecture

### ShutdownManager (`HealthDebugKit/Health/ShutdownManager.swift`)

`@MainActor` singleton:

- **State machine**: `inactive` → `active` → (optionally `violated`)
- **Countdown timer**: Updates every second based on `SleepConfig`
- **Food safety check**: `isAllowedDuringShutdown()` validates items
- **Flare risk assessment**: `none`, `moderate` (general food), `high` (acidic/spicy/dairy)

### ShutdownView (`HealthDebug/iOS/ShutdownView.swift`)

Full-screen view with:
- Countdown ring (green when inactive, orange when active)
- Status card with contextual messaging
- Allowed items list with icons
- Educational info card about GERD/sinus connection

### Dashboard Integration (`HealthDebug/iOS/ContentView.swift`)

Summary card showing shutdown state and live countdown.

## Data Dependencies

- `SleepConfig.targetSleepHour/Minute` — bedtime
- `SleepConfig.shutdownWindowHours` — fasting window (default: 4)
- `SleepConfig.shutdownStartTime` — computed: bedtime minus window

## Allowed Items During Shutdown

| Item | Reason |
|------|--------|
| Water | Essential hydration, no reflux risk |
| Chamomile Tea | Anti-inflammatory, soothes digestive tract |
| Anise Tea | Reduces bloating, anti-spasmodic |

## High-Risk Foods (During Shutdown)

Spicy, fried, dairy, chocolate, citrus, tomato, coffee, soda, alcohol, mint — these trigger both GERD and sinus inflammation.
