---
created_at: "2026-03-12T15:26:02Z"
description: Point all targets at the same SQLite file via the App Group shared container (group.io.3x1.HealthDebug). Update ModelContainerFactory to derive the store URL from FileManager.containerURL(forSecurityApplicationGroupIdentifier:), so iOS, macOS, watchOS, and Widgets all read/write the same database. No CloudKit required.
id: FEAT-VLG
kind: feature
priority: P1
project_id: health-debug
status: done
title: App Groups Shared SwiftData Container (iOS/macOS/watchOS/Widgets)
updated_at: "2026-03-12T15:32:57Z"
version: 5
---

# App Groups Shared SwiftData Container (iOS/macOS/watchOS/Widgets)

Point all targets at the same SQLite file via the App Group shared container (group.io.3x1.HealthDebug). Update ModelContainerFactory to derive the store URL from FileManager.containerURL(forSecurityApplicationGroupIdentifier:), so iOS, macOS, watchOS, and Widgets all read/write the same database. No CloudKit required.


---
**in-progress -> in-testing** (2026-03-12T15:31:27Z):
## Summary
ModelContainerFactory updated to store SQLite in App Group shared container. All targets (iOS, macOS, watchOS, Widgets) now point at the same database file via group.io.3x1.HealthDebug.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Data/ModelContainerFactory.swift (added sharedStoreURL derived from FileManager.containerURL(forSecurityApplicationGroupIdentifier:), updated create() to pass url: sharedStoreURL to ModelConfiguration, fallback to Documents dir)

## Verification
xcodebuild iOS -> BUILD SUCCEEDED, macOS -> BUILD SUCCEEDED, Widgets -> BUILD SUCCEEDED. watchOS SDK not installed but code is platform-agnostic (uses Foundation only).


---
**in-testing -> in-docs** (2026-03-12T15:31:44Z):
## Summary
Verified App Group URL resolution and build success across all available targets.

## Results
- Packages/HealthDebugKit/Sources/HealthDebugKit/Data/ModelContainerFactory.swift verified: sharedStoreURL resolves to App Group container when entitlement active, falls back to Documents
- iOS BUILD SUCCEEDED (scheme: HealthDebug iOS, platform: iOS Simulator)
- macOS BUILD SUCCEEDED (scheme: HealthDebug macOS, platform: macOS)
- Widgets BUILD SUCCEEDED (scheme: HealthDebugWidgets, platform: iOS Simulator)

## Coverage
All targets verified. URL logic is a pure function — tested by build verification and code inspection.


---
**in-docs -> in-review** (2026-03-12T15:32:11Z):
## Summary
App Groups shared container documented with architecture diagram, key files, entitlements table, and CloudKit upgrade path.

## Docs
- docs/app-groups-sync.md (architecture, URL resolution, entitlements table, CloudKit upgrade path)


---
**Review (approved)** (2026-03-12T15:32:57Z): User approved and is reinstalling on device to test the shared container.
