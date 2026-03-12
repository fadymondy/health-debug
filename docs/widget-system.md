# Widget System

Health Debug exposes all 11 dashboard cards as native WidgetKit widgets for iOS home screen, lock screen, and macOS desktop.

## Architecture

```
App (main process)
  └─ managers publish data
       └─ WidgetRefresher.refresh(...) → WidgetDataStore.write(snapshot)
                                          └─ WidgetCenter.reloadAllTimelines()

Widget Extension (separate process)
  └─ HealthTimelineProvider.getTimeline() → WidgetDataStore.read()
       └─ renders HealthWidgetEntry with WidgetSnapshot
```

## Shared Data Layer

`WidgetSnapshot` is a `Codable` struct written to `UserDefaults(suiteName: "group.io.3x1.HealthDebug")` under key `widget_snapshot_v1`.

The main app uses `WidgetDataStore` from `HealthDebugKit`. The widget extension uses a standalone copy in `WidgetShared.swift` to avoid linking HealthKit.

## Key Files

- `Packages/HealthDebugKit/Sources/HealthDebugKit/Data/WidgetDataStore.swift` — shared model + writer
- `Packages/HealthDebugKit/Sources/HealthDebugKit/Data/WidgetRefresher.swift` — refresh trigger
- `HealthDebugWidgets/WidgetShared.swift` — widget-process copy
- `HealthDebugWidgets/WidgetTimelineProvider.swift` — timeline provider (15-min refresh)
- `HealthDebugWidgets/HealthDebugWidgetBundle.swift` — widget bundle entry point

## Lock Screen Widgets

Six lock screen widgets in `HealthDebugWidgets/LockScreenWidgets.swift`:

| Widget | Circular | Rectangular |
|--------|---------|-------------|
| StepsLockWidget | Gauge ring + abbreviated count | Icon + label + count |
| HeartRateLockWidget | Gauge + BPM | Icon + BPM + zone |
| HydrationLockWidget | Gauge ring + ml | Icon + "X/Y ml" |
| StandTimerLockWidget | Gauge + session count | Icon + sessions + phase |
| SleepLockWidget | Gauge + hours | Icon + hours + quality |
| DailyFlowLockWidget | Gauge + "X/6" | Icon + score + percentage |

All use `.widgetAccentable()` for system vibrant tinting on lock screen.

## In-App Widget Gallery

`HealthDebug/iOS/WidgetGalleryView.swift` — accessible from Dashboard → Edit → Widget Gallery.

- 2-column grid of all 11 widget cards with glass previews
- Family size chips (Small/Medium/Large) + Lock Screen badge
- Tap any card → `WidgetDetailSheet` with step-by-step instructions for home screen and lock screen placement
- `HowToAddCard` at the bottom for general instructions

## Widget Data Refresh

`ContentView.refreshWidgets()` is called on `.onAppear` and pull-to-refresh. It collects values from all managers and calls `WidgetRefresher.refresh(...)`, which writes a `WidgetSnapshot` to the shared App Group and triggers `WidgetCenter.reloadAllTimelines()`.

## Adding a New Widget

1. Add a new `Widget` struct in `HealthDebugWidgets/Widgets/`
2. Register it in `HealthDebugWidgetBundle.swift`
3. Add a `WidgetCard` entry to `allWidgetCards` in `WidgetGalleryView.swift`
