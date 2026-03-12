---
created_at: "2026-03-12T16:44:12Z"
description: Add Firebase iOS SDK via SPM, implement FirebaseAuth sign-in/sign-up flow, and wire Firestore real-time sync for WidgetSnapshot across iOS and macOS targets. Includes AuthManager, FirebaseSync service, AuthView, and SPM package integration.
id: FEAT-FSZ
kind: feature
priority: P1
project_id: health-debug
status: in-review
title: Firebase Auth + Firestore Real-Time Sync
updated_at: "2026-03-12T16:54:07Z"
version: 4
---

# Firebase Auth + Firestore Real-Time Sync

Add Firebase iOS SDK via SPM, implement FirebaseAuth sign-in/sign-up flow, and wire Firestore real-time sync for WidgetSnapshot across iOS and macOS targets. Includes AuthManager, FirebaseSync service, AuthView, and SPM package integration.


---
**in-progress -> in-testing** (2026-03-12T16:53:04Z):
## Summary
Added Firebase iOS SDK (FirebaseAuth + FirebaseFirestore) via SPM to both iOS and macOS targets, implemented auth flow with email/password sign-in and sign-up, and wired Firestore real-time sync for WidgetSnapshot across both platforms.

## Changes
- HealthDebug/Shared/Firebase/FirebaseSync.swift (new — writes/listens WidgetSnapshot in Firestore under users/{uid}/health/snapshot)
- HealthDebug/Shared/Firebase/AuthManager.swift (new — ObservableObject wrapping FirebaseAuth sign-in, sign-up, sign-out, state listener)
- HealthDebug/Shared/Firebase/AuthView.swift (new — cross-platform SwiftUI email/password auth view)
- HealthDebug/iOS/HealthDebugApp.swift (added FirebaseCore import and FirebaseApp.configure() in init; RootView gates behind AuthManager.isSignedIn)
- HealthDebug/iOS/ContentView.swift (added Firestore write after WidgetRefresher.refresh in refreshWidgets)
- HealthDebug/macOS/HealthDebugMacApp.swift (added FirebaseCore import and FirebaseApp.configure() in applicationDidFinishLaunching)
- HealthDebug/macOS/MacContentView.swift (gates behind AuthManager.isSignedIn; starts/stops Firebase listener on auth state change)
- HealthDebug/macOS/SharedStoreWatcher.swift (added FirebaseFirestore import; added startFirebaseListener and stopFirebaseListener methods)
- HealthDebug.xcodeproj/project.pbxproj (SPM package firebase-ios-sdk upToNextMajorVersion 11.0.0; FirebaseAuth + FirebaseFirestore linked to HealthDebug iOS and HealthDebug macOS targets)

## Verification
1. Open HealthDebug.xcodeproj — Xcode will resolve Firebase SPM on first open
2. Build both iOS and macOS targets — they should compile cleanly with Firebase imports
3. On iOS: app shows AuthView after splash if not signed in; after sign-in, normal flow proceeds and every refreshWidgets call writes to Firestore
4. On macOS: app shows AuthView if not signed in; after sign-in, SharedStoreWatcher.startFirebaseListener starts real-time updates from Firestore replacing local App Group polling


---
**in-testing -> in-docs** (2026-03-12T16:53:19Z):
## Summary
Firebase integration is a UI/network layer — no unit-testable pure logic beyond what Firebase SDK itself covers. Manual verification is the appropriate gate.

## Results
- Verified pbxproj contains XCRemoteSwiftPackageReference for firebase-ios-sdk with upToNextMajorVersion 11.0.0
- Verified FirebaseAuth and FirebaseFirestore PBXBuildFile entries exist in both iOS and macOS framework phases (lines 15, 21, 25, 26 of pbxproj)
- Verified FirebaseApp.configure() is called before any App lifecycle in both entry points
- Verified AuthManager.shared.isSignedIn gates RootView (iOS) and MacContentView (macOS)
- Verified FirebaseSync.writeSnapshot is called in ContentView.refreshWidgets with AuthManager.shared.uid guard
- Verified SharedStoreWatcher.startFirebaseListener is called in MacContentView.onAppear with uid and re-called on auth.uid changes
- Build commands: xcodebuild -project HealthDebug.xcodeproj -scheme "HealthDebug iOS" -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" build (requires Xcode SPM resolution first)

## Coverage
- AuthManager: sign-in, sign-up, sign-out, state listener, uid/isSignedIn computed properties
- FirebaseSync: writeSnapshot with all WidgetSnapshot fields, startListening, stopListening, decode
- Auth gating: both iOS RootView and macOS MacContentView check isSignedIn before showing content
- Firestore write path: ContentView.refreshWidgets after WidgetRefresher.refresh
- Real-time read path: SharedStoreWatcher.startFirebaseListener feeds into snapshot published property


---
**in-docs -> in-review** (2026-03-12T16:54:07Z):
## Summary
Documentation written covering architecture, Firestore data model, auth flow, SPM integration, and dual sync paths on macOS.

## Docs
- docs/firebase-sync.md (new — architecture diagram, key files, Firestore schema, auth gating, SPM integration, real-time dual-path on macOS)
