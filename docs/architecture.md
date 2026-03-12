# Architecture

## Platform Targets

| Platform | Entry Point | UI Pattern |
|----------|------------|------------|
| iOS 18+ | `HealthDebugApp.swift` | NavigationStack dashboard |
| macOS 15+ | `HealthDebugMacApp.swift` | MenuBarExtra (hydration/stand) + WindowGroup (full dashboard) |
| watchOS 11+ | `HealthDebugWatchApp.swift` | List-based hydration + stand UI |

## Shared Package

All business logic lives in `Packages/HealthDebugKit/`:

```
HealthDebugKit/
├── Sources/HealthDebugKit/
│   ├── HealthDebugKit.swift       # Entry point
│   ├── Data/
│   │   ├── ModelContainerFactory.swift  # Centralized container creation
│   │   └── Queries.swift                # Fetch descriptors & aggregates
│   └── Models/                    # SwiftData models
│       ├── WaterLog.swift
│       ├── MealLog.swift
│       ├── StandSession.swift
│       ├── CaffeineLog.swift
│       ├── SleepConfig.swift
│       └── UserProfile.swift
└── Tests/HealthDebugKitTests/
    └── HealthDebugKitTests.swift
│   ├── Health/
│   │   └── HealthKitManager.swift     # HealthKit read/write
│   └── Protocols/
│       └── FoodRegistry.swift         # Safe/unsafe food classifier
└── Tests/HealthDebugKitTests/
    └── HealthDebugKitTests.swift
```

All 3 platform targets depend on `HealthDebugKit` as a local Swift package.

## HealthKit Integration

`HealthKitManager` is a `@MainActor` singleton that reads health data on iOS and watchOS (not macOS):

| Metric | HealthKit Type | Method |
|--------|---------------|--------|
| Steps | `.stepCount` | `fetchTodaySteps()` |
| Active Energy | `.activeEnergyBurned` | `fetchTodayActiveEnergy()` |
| Heart Rate | `.heartRate` | `fetchLatestHeartRate()` |
| Sleep | `.sleepAnalysis` | `fetchLastNightSleep()` |
| Weight | `.bodyMass` | `fetchZeppMetrics()` |
| Body Fat | `.bodyFatPercentage` | `fetchZeppMetrics()` |

- **Zepp Scale**: Weight and body fat from Zepp smart scale sync through Apple Health. Bundled in `ZeppMetrics` struct.
- **Sleep**: Filters only asleep categories (core, deep, REM, unspecified) — excludes "inBed".
- **Authorization**: Requests read-only access. All types in `readTypes` set.
- **Refresh**: `refreshAll()` fetches all metrics in sequence with error logging.

## Data Sync

- **SwiftData** backed by **CloudKit** (`iCloud.io.3x1.HealthDebug`)
- **App Group** (`group.io.3x1.HealthDebug`) for shared container access (widgets, extensions)
- All models sync automatically across iOS, macOS, and watchOS

## Entitlements

| Capability | iOS | macOS | watchOS |
|-----------|-----|-------|---------|
| HealthKit | Yes | No | Yes |
| CloudKit | Yes | Yes | Yes |
| App Group | Yes | Yes | Yes |
| App Sandbox | N/A | Yes | N/A |
| Network Client | N/A | Yes | N/A |

## Bundle IDs

- iOS: `io.threex1.HealthDebug`
- macOS: `io.threex1.HealthDebug.mac`
- watchOS: `io.threex1.HealthDebug.watchkitapp`
