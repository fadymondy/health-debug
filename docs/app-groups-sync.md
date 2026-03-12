# App Groups Shared Container Sync

## Overview

All targets share a single SQLite file via the App Group `group.io.3x1.HealthDebug`.
No CloudKit, no network — zero-latency reads from the same on-device database.

## How It Works

```
iOS App  ──┐
macOS App ──┼──► group.io.3x1.HealthDebug/HealthDebug.sqlite
watchOS ───┤
Widgets ───┘
```

`ModelContainerFactory.sharedStoreURL` resolves the path:

```swift
FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.io.3x1.HealthDebug"
)?.appendingPathComponent("HealthDebug.sqlite")
```

Falls back to the app's own `Documents/` directory if the App Group container is unavailable (e.g. Mac Catalyst simulator without entitlements).

## Key File

`Packages/HealthDebugKit/Sources/HealthDebugKit/Data/ModelContainerFactory.swift`

- `appGroupID` — `"group.io.3x1.HealthDebug"`
- `storeFileName` — `"HealthDebug.sqlite"`
- `sharedStoreURL` — computed property, resolves App Group URL with fallback
- `create(inMemory:)` — passes `url: sharedStoreURL` to `ModelConfiguration`
- `preview()` — in-memory only, unchanged

## Entitlements

All targets already have the App Group entitlement:

| Target | Entitlements file |
|--------|------------------|
| iOS | `HealthDebug/iOS/HealthDebug.entitlements` |
| macOS | `HealthDebug/macOS/HealthDebugMac.entitlements` |
| watchOS | `HealthDebug/watchOS Watch App/HealthDebugWatch.entitlements` |
| Widgets | `HealthDebugWidgets/HealthDebugWidgets.entitlements` |

## CloudKit Upgrade Path

When a paid Apple Developer account is active:

1. Change `cloudKitDatabase: .none` → `.automatic` in `ModelContainerFactory.create()`
2. Ensure `iCloud.io.3x1.HealthDebug` container is provisioned
3. App Groups sync continues to work alongside CloudKit (iCloud syncs across devices, App Groups syncs between targets on the same device)
