# User Profile & Onboarding Flow

## Overview

First-launch onboarding collects baseline health data and configures work/sleep schedules. The app gates dashboard access until onboarding is complete.

## Flow

1. **Welcome** — App introduction with Health Debug branding
2. **Baseline Metrics** — Pre-filled body composition from Zepp scale (editable):
   - Weight: 108 kg, Height: 179 cm, Muscle Mass: 66.9 kg
   - Metabolic Age: 53, Visceral Fat: 14, Body Water: 46.7%
   - Targets: Weight 90 kg, Visceral Fat <10, Body Water >55%, Metabolic Age <35
3. **Work Window** — Work start/end times + daily water goal (2500 ml default)
4. **Sleep Schedule** — Target bedtime + GERD shutdown window (hours before bed)

## Data Storage

- `UserProfile` — SwiftData model with all baseline metrics, targets, work window, and `onboardingCompleted` flag
- `SleepConfig` — Separate SwiftData model for sleep schedule and shutdown window

## App Entry Gate

`RootView` in `HealthDebugApp.swift` queries `UserProfile` via SwiftData `@Query`. If no profile exists or `onboardingCompleted == false`, the onboarding flow is shown instead of the dashboard.

## Post-Onboarding Access

The dashboard toolbar has a gear icon that opens `ProfileSettingsView` as a sheet, allowing users to edit all profile and sleep settings at any time.

## Files

| File | Purpose |
|------|---------|
| `HealthDebug/iOS/OnboardingView.swift` | 4-step onboarding flow |
| `HealthDebug/iOS/ProfileSettingsView.swift` | Profile editor (settings sheet) |
| `HealthDebug/iOS/HealthDebugApp.swift` | RootView with onboarding gate |
| `HealthDebug/iOS/ContentView.swift` | Dashboard with settings button |
| `Packages/HealthDebugKit/.../UserProfile.swift` | User profile SwiftData model |
| `Packages/HealthDebugKit/.../SleepConfig.swift` | Sleep config SwiftData model |
