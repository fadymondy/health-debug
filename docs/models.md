# SwiftData Models

All models are `@Model` classes in `HealthDebugKit`, synced via CloudKit.

## WaterLog

Tracks hydration entries for the Gout Protocol Engine.

| Property | Type | Description |
|----------|------|-------------|
| `amount` | `Int` | Milliliters (default: 250) |
| `timestamp` | `Date` | When logged |
| `source` | `String` | Origin: "watch", "menubar", "ios" |

## MealLog

Boolean safe/unsafe meal tracking with trigger warnings.

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Food item name |
| `category` | `String` | FoodCategory: protein, carb, fat, drink, snack |
| `isSafe` | `Bool` | Whitelist (true) or blacklist (false) |
| `triggers` | `[String]` | TriggerType: "IBS/GERD", "Gout", "Fatty Liver" |
| `timestamp` | `Date` | When logged |
| `notes` | `String` | Optional notes |

## StandSession

Tracks Pomodoro stand/walk sessions.

| Property | Type | Description |
|----------|------|-------------|
| `startTime` | `Date` | Session start |
| `durationSeconds` | `Int` | Target: 180 (3 minutes) |
| `completed` | `Bool` | Whether the walk was completed |

## CaffeineLog

Tracks caffeine intake for the Red Bull Deprecation protocol.

| Property | Type | Description |
|----------|------|-------------|
| `type` | `String` | CaffeineType: Red Bull, Cold Brew, Matcha, etc. |
| `isSugarBased` | `Bool` | Auto-set from CaffeineType |
| `timestamp` | `Date` | When consumed |

### CaffeineType Enum

| Value | Sugar-Based | Clean |
|-------|------------|-------|
| Red Bull | Yes | No |
| Cold Brew | No | Yes |
| Matcha | No | Yes |
| Green Tea | No | Yes |
| Espresso | No | Yes |
| Black Coffee | No | Yes |

## SleepConfig

Configures the GERD System Shutdown timer.

| Property | Type | Description |
|----------|------|-------------|
| `targetSleepHour` | `Int` | 0-23 |
| `targetSleepMinute` | `Int` | 0-59 |
| `shutdownWindowHours` | `Int` | Default: 4 hours before sleep |
| `lastUpdated` | `Date` | Last config change |

Computed: `shutdownStartTime` — calculates when System Shutdown mode begins.

## UserProfile

Stores baseline metrics and targets.

| Property | Type | Baseline | Target |
|----------|------|----------|--------|
| `weightKg` | `Double` | 108 | Gradual decrease |
| `heightCm` | `Double` | 179 | — |
| `muscleMassKg` | `Double` | 66.9 | — |
| `metabolicAge` | `Int` | 53 | < 35 |
| `visceralFat` | `Int` | 14 | < 10 |
| `bodyWaterPercent` | `Double` | 46.7% | > 55% |
| `dailyWaterGoalMl` | `Int` | 2500 | — |

Work window: `workStartHour/Minute` to `workEndHour/Minute` (default: 9:00–19:00).

Computed: `bmi`, `workWindowHours`.
