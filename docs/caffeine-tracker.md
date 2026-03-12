# Focus & Red Bull Deprecation Tracker

## Overview

Tracks caffeine intake with a focus on transitioning from sugar-based energy drinks (Red Bull) to clean caffeine sources. Includes a 90-minute post-wake caffeine block based on cortisol science and fatty liver alerts for sugar-based drinks.

## How It Works

1. **Caffeine Block** — First 90 minutes after waking, caffeine is blocked (cortisol is naturally high)
2. **Quick Log** — Tap any caffeine type to log: Red Bull, Cold Brew, Matcha, Green Tea, Espresso, Black Coffee, Other
3. **Transition Score** — Tracks clean vs sugar-based caffeine as a percentage (0% = all Red Bull, 100% = all clean)
4. **Fatty Liver Alert** — Any sugar-based caffeine triggers a warning about liver fat accumulation

## Architecture

### CaffeineManager (`HealthDebugKit/Health/CaffeineManager.swift`)

`@MainActor` singleton:

- **Caffeine block**: Uses work start hour minus 1 as wake time proxy, blocks for 90 minutes
- **Transition tracking**: `cleanTransitionPercent` (0-100%), `transitionStatus` (Clean/Transitioning/Red Bull Dependent)
- **Fatty liver**: `fattyLiverAlert` flag when any sugar-based caffeine is logged

### CaffeineView (`HealthDebug/iOS/CaffeineView.swift`)

- Caffeine block status card (green/orange)
- Transition ring with percentage
- Quick-log grid (7 caffeine types with icons)
- Liver health card with clean/sugar counts
- Today's intake history

### Dashboard Integration (`HealthDebug/iOS/ContentView.swift`)

Summary card showing transition status, clean/sugar counts, and percentage.

## Data Model

`CaffeineLog` (`HealthDebugKit/Models/CaffeineLog.swift`):
- `type: String` (CaffeineType raw value)
- `isSugarBased: Bool`
- `timestamp: Date`

`CaffeineType` enum:
- Sugar-based: Red Bull
- Clean: Cold Brew, Matcha, Green Tea, Espresso, Black Coffee
- Other

## Caffeine Block Science

Cortisol peaks 30-45 minutes after waking. Consuming caffeine during this window:
- Doesn't improve alertness (cortisol already handles it)
- Builds caffeine tolerance faster
- Can increase afternoon energy crashes

Waiting 90 minutes lets cortisol naturally decline, making caffeine more effective.
