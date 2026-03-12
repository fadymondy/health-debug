# Firebase Auth + Firestore Real-Time Sync

## Overview

Health Debug uses Firebase to bridge the iOS and macOS apps with real-time data sync. iOS writes `WidgetSnapshot` data to Firestore after every health refresh, and macOS subscribes to a live snapshot listener so the dashboard stays current without needing the App Group to cross machine boundaries.

## Architecture

```
iPhone (iOS app)
  └── ContentView.refreshWidgets()
        └── WidgetRefresher.refresh(...)    ← writes App Group UserDefaults
        └── FirebaseSync.writeSnapshot()    ← writes Firestore
              └── users/{uid}/health/snapshot

Mac (macOS app)
  └── SharedStoreWatcher.startFirebaseListener()
        └── FirebaseSync.startListening()   ← Firestore real-time listener
              └── snapshot updates → SharedStoreWatcher.snapshot → UI
```

## Key Files

| File | Purpose |
|------|---------|
| `HealthDebug/Shared/Firebase/AuthManager.swift` | ObservableObject wrapping FirebaseAuth — sign-in, sign-up, sign-out, state listener |
| `HealthDebug/Shared/Firebase/FirebaseSync.swift` | Writes and listens to `WidgetSnapshot` in Firestore |
| `HealthDebug/Shared/Firebase/AuthView.swift` | Cross-platform SwiftUI email/password sign-in view |
| `HealthDebug/iOS/HealthDebugApp.swift` | Calls `FirebaseApp.configure()` in `init()` |
| `HealthDebug/macOS/HealthDebugMacApp.swift` | Calls `FirebaseApp.configure()` in `applicationDidFinishLaunching` |
| `HealthDebug/iOS/ContentView.swift` | Calls `FirebaseSync.shared.writeSnapshot` after every widget refresh |
| `HealthDebug/macOS/MacContentView.swift` | Auth gate + starts Firebase listener on sign-in |
| `HealthDebug/macOS/SharedStoreWatcher.swift` | `startFirebaseListener` / `stopFirebaseListener` methods |

## Firebase SPM Integration

The Firebase iOS SDK is added via Swift Package Manager:

- **URL:** `https://github.com/firebase/firebase-ios-sdk`
- **Version rule:** Up to next major from `11.0.0`
- **Products linked to both targets:** `FirebaseAuth`, `FirebaseFirestore`
- **FirebaseCore** is imported in entry points only (not exposed to Shared files)

## Firestore Data Model

```
users/
  {uid}/
    health/
      snapshot/       ← single document, overwritten on each refresh
        steps: Double
        stepsGoal: Double
        activeEnergy: Double
        energyGoal: Double
        heartRate: Double
        sleepHours: Double
        sleepGoal: Double
        hydrationMl: Int
        hydrationGoalMl: Int
        pomodoroCompleted: Int
        pomodoroTarget: Int
        pomodoroPhase: String
        nutritionSafetyScore: Int
        mealsLogged: Int
        caffeineIsClean: Bool
        caffeineDrinksToday: Int
        caffeineDrinksClean: Int
        shutdownActive: Bool
        shutdownSecondsRemaining: TimeInterval
        weightKg: Double
        weightBodyFat: Double
        dailyFlowScore: Int
        dailyFlowTotal: Int
        updatedAt: Timestamp
```

## Auth Flow

Both iOS and macOS gate their main content behind `AuthManager.isSignedIn`:

- **iOS (`RootView`):** After the splash screen, if `!auth.isSignedIn`, shows `AuthView`. On successful sign-in the view tree transitions to `OnboardingView` or `MainAppView`.
- **macOS (`MacContentView`):** Shows `AuthView` if not signed in. On sign-in, shows the main `TabView` and immediately starts the Firestore listener.

## GoogleService-Info.plist

Each target requires its own `GoogleService-Info.plist` from the Firebase Console:

- `HealthDebug/iOS/GoogleService-Info.plist` — iOS bundle ID `io.threex1.HealthDebug`
- `HealthDebug/macOS/GoogleService-Info.plist` — macOS bundle ID `io.threex1.HealthDebug.mac`

Both plists are already present in the project directory.

## Real-Time Sync on macOS

`SharedStoreWatcher` now has two data paths running in parallel:

1. **Local App Group** — file watcher + 5-second poll (works on same machine, same iCloud account)
2. **Firestore listener** — real-time push from any iOS device signed in to the same Firebase account

The Firebase path updates `watcher.snapshot` and fires `didChange` using the same pattern as the local watcher, so all macOS views re-render identically regardless of which path delivers the data.
