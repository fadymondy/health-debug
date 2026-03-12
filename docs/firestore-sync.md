# Firestore Sync Architecture

## Overview

Firestore is the **single source of truth** for user profile and health data, enabling cross-platform access (iOS, macOS, future Android).

SwiftData serves as an offline cache — always updated from Firestore, not the primary store.

## Firestore Schema

```
users/{uid}/
  profile/data          — UserProfile + SleepConfig (written on onboarding + settings saves)
  healthkit/today       — HealthKit snapshot (steps, HR, sleep, weight, energy)
  health/snapshot       — Widget snapshot (existing, written by FirebaseSync)
```

## Key Files

| File | Role |
|------|------|
| `HealthDebug/Shared/Firebase/FirestoreSyncService.swift` | Writes profile and HealthKit snapshot to Firestore |
| `HealthDebug/Shared/Firebase/ProfileStore.swift` | Firestore-first ObservableObject; real-time listener + SwiftData cache fallback |
| `HealthDebug/iOS/HealthDebugApp.swift` | Starts/stops ProfileStore listener on auth changes; triggers HealthKit sync on first launch |

## Data Flow

### On Sign-Up (onboarding completion)
1. `SignUpOnboardingView.finishOnboarding()` saves to SwiftData
2. Calls `FirestoreSyncService.syncProfile()` → writes `users/{uid}/profile/data`
3. Calls `FirestoreSyncService.syncHealthKitSnapshot()` → writes `users/{uid}/healthkit/today`

### On App Launch (existing user)
1. `RootView.onAppear` calls `ProfileStore.startListening(uid:modelContext:)`
2. Firestore real-time listener fires → profile loaded into `ProfileStore.profile`
3. SwiftData cache updated from Firestore data
4. On first biometric unlock: HealthKit snapshot written to Firestore

### On Profile Settings Save
1. `ProfileSettingsView.save()` writes to SwiftData
2. Calls `FirestoreSyncService.syncProfile()` → Firestore updated

### On Sign-Out
- `ProfileStore.stopListening()` — listener removed, memory cleared
- `healthKitSyncedThisSession` reset so next sign-in triggers a fresh snapshot
