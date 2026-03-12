# Setup

## Requirements

- **Xcode 16.2+**
- **macOS 15.0+** (Sequoia)
- Apple Developer account (for CloudKit and HealthKit capabilities)

## Build

```bash
# Open in Xcode
open HealthDebug.xcodeproj

# Build shared package standalone
cd Packages/HealthDebugKit && swift build

# Run package tests
cd Packages/HealthDebugKit && swift test
```

## Configuration

### 1. Development Team

Set your development team in each target's Signing & Capabilities:
- HealthDebug iOS
- HealthDebug macOS
- HealthDebug watchOS

### 2. CloudKit Container

The project uses `iCloud.io.3x1.HealthDebug`. Ensure this container exists in your Apple Developer portal.

### 3. App Group

All targets share `group.io.3x1.HealthDebug` for SwiftData container access across the main app and extensions (widgets).

### 4. HealthKit

iOS and watchOS targets have HealthKit entitlements. The app reads:
- Steps
- Active Energy
- Heart Rate
- Sleep Analysis
- Body Mass (Zepp scale via Apple Health)
- Body Fat Percentage
- Body Water (if available)

## Targets

| Target | SDK | Deployment |
|--------|-----|------------|
| HealthDebug iOS | iphoneos | iOS 18.0 |
| HealthDebug macOS | macosx | macOS 15.0 |
| HealthDebug watchOS | watchos | watchOS 11.0 |
