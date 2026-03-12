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

## Xcode Target Setup

The widget extension is registered as `HealthDebugWidgets` in `HealthDebug.xcodeproj`:

- **Product type**: `com.apple.product-type.app-extension`
- **Bundle ID**: `io.threex1.HealthDebug.widgets`
- **Extension point**: `com.apple.widgetkit-extension` (in `HealthDebugWidgets/Info.plist`)
- **Embed phase**: `HealthDebug iOS` target → Embed Foundation Extensions → `HealthDebugWidgets.appex`
- **Signing**: `DEVELOPMENT_TEAM = JW9HJH86GC`, `CODE_SIGN_STYLE = Automatic`

The widget extension does **not** link `HealthDebugKit` to avoid pulling in HealthKit entitlements. All shared data flows through the App Group UserDefaults via `WidgetShared.swift`.

## Interactive Widgets (AppIntents)

Three widgets support in-place action buttons (iOS 17+, no app launch needed):

| Widget | Button | Action |
|--------|--------|--------|
| Hydration (Medium) | +250ml | `LogHydration250Intent` — queues 250ml in App Group |
| Hydration (Medium) | +500ml | `LogHydration500Intent` — queues 500ml in App Group |
| Stand Timer (Medium) | Start / Break | `StartFocusIntent` / `TakeBreakIntent` — context-aware |
| Caffeine (Medium) | Log Clean Drink | `LogCleanDrinkIntent` — queues espresso log |

**Architecture:**
1. Widget button taps an `AppIntent` (in `HealthDebugWidgets/WidgetActions.swift`)
2. Intent writes a pending command to App Group UserDefaults (`widget_action_*` keys)
3. `WidgetCenter.shared.reloadTimelines(ofKind:)` refreshes the widget display
4. When the main app comes to foreground, `ContentView.flushWidgetActions()` calls `WidgetActionReader.shared` to consume and execute each pending action

**Key files:**
- `HealthDebugWidgets/WidgetActions.swift` — all AppIntents + `WidgetActionStore` writer
- `Packages/HealthDebugKit/Sources/HealthDebugKit/Data/WidgetDataStore.swift` — `WidgetActionReader` consumer
- `HealthDebug/iOS/ContentView.swift` — `flushWidgetActions()` called on `.onAppear`

## Deep Links

Tapping any widget (outside a button) opens the app directly to that widget's detail screen via the `healthdebug://` URL scheme. Registered in `HealthDebug/iOS/Info.plist` → `CFBundleURLTypes`. Handled by `onOpenURL` in `MainAppView`.

## Adding a New Widget

1. Add a new `Widget` struct in `HealthDebugWidgets/Widgets/`
2. Register it in `HealthDebugWidgetBundle.swift`
3. Add a `WidgetCard` entry to `allWidgetCards` in `WidgetGalleryView.swift`
4. (Optional) Add an `AppIntent` in `WidgetActions.swift` + a consumer in `WidgetActionReader`
