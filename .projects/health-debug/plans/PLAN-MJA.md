---
created_at: "2026-03-11T23:44:27Z"
description: |-
    # Health Debug v1.0 — Implementation Plan

    ## Overview
    Build a multi-platform Apple ecosystem app (iOS, macOS Menu Bar, watchOS) for personal AI health & metabolic tracking. The app targets a 31-year-old desk-bound software engineer looking to reverse: Gout, High Triglycerides, Fatty Liver, GERD, IBS, Sinusitis, Dehydration, and Caffeine/Sugar dependency.

    ## Tech Stack
    - **Languages:** Swift 6, SwiftUI
    - **Data:** SwiftData + CloudKit (cross-device sync)
    - **Health:** HealthKit (read/write)
    - **Widgets:** WidgetKit
    - **AI:** Apple Intelligence (App Intents) + BYOK fallback (Claude/GPT/Gemini)
    - **Platforms:** iOS 18+, macOS 15+, watchOS 11+

    ## Architecture Approach
    - **Shared Swift Package** (`HealthDebugKit`) containing all models, business logic, and data layer — consumed by iOS, macOS, and watchOS targets
    - **SwiftData models** with CloudKit backing for seamless sync
    - **Protocol-oriented design** for health rules engine (Whitelist/Blacklist, timers, alerts)

    ## Epic Breakdown (13 Features)

    ### Phase 1: Foundation (Features 1-4)
    1. **Project Scaffold & Multi-Platform Setup** (chore) — Xcode project with iOS/macOS/watchOS targets, shared Swift package, SwiftData models, CloudKit container config
    2. **SwiftData Models & CloudKit Sync** (feature) — Core data models: WaterLog, MealLog, StandSession, CaffeineLog, SleepConfig, UserProfile with Zepp baseline metrics. CloudKit sync validation.
    3. **HealthKit Integration Layer** (feature) — Read/write steps, active energy, heart rate, sleep. Zepp scale metrics ingestion (weight, visceral fat, body water, metabolic age).
    4. **User Profile & Onboarding** (feature) — First-launch onboarding capturing baseline data (108kg, visceral fat 14, etc.), target sleep time, work window hours.

    ### Phase 2: Core Health Modules (Features 5-9)
    5. **Epic 1: Desk-Job Hack — 90-Min Pomodoro Stand Tracker** (feature) — Background timer, 90-min intervals, critical alerts on macOS + watchOS, 3-min walk tracking. Insulin sensitivity protocol.
    6. **Epic 2: Hydration & Gout Protocol Engine** (feature) — 2.5L daily goal distributed across 10-hour work window, +250ml quick-log on watchOS & macOS menu bar, uric acid flush tracking.
    7. **Epic 3: GERD & Sinus System Shutdown Timer** (feature) — 4-hour pre-sleep fasting countdown, "System Shutdown" mode, herbal tea allowance, GERD/Sinus flare-up risk exceptions on food logging.
    8. **Epic 4: Focus & Red Bull Deprecation Tracker** (feature) — 90-120 min post-wake caffeine block, clean caffeine transition tracking (Red Bull → Cold Brew/Matcha), fatty liver alerts on sugar caffeine.
    9. **Epic 5: Safe Mode Nutrition Logger** (feature) — Boolean safe/unsafe meal tracking with predefined whitelist/blacklist. IBS/GERD/Gout/Fatty Liver trigger warnings. Fast-logging for safe foods.

    ### Phase 3: AI & Intelligence (Feature 10)
    10. **Epic 6: AI Analytics & RAG System** (feature) — Apple Intelligence integration via App Intents, BYOK settings (Claude/GPT/Gemini API keys), local RAG pipeline over SwiftData, 72-hour context retrieval, JSON export to iCloud Drive for CLI analysis.

    ### Phase 4: UI/UX Polish (Features 11-13)
    11. **Theme System — Light/Dark Mode with IDE Aesthetic** (feature) — Semantic colors, neon green accents in dark mode, clinical white/grey in light mode, tech-oriented tone of voice throughout UI.
    12. **Localization — Arabic (RTL) & English (LTR)** (feature) — Full i18n with LocalizedStringKey, RTL layout support, SF Arabic fonts, dynamic type scaling.
    13. **WidgetKit & Menu Bar Integration** (feature) — iOS widgets (hydration, stand ring, meal status), macOS menu bar app (hydration quick-log, Pomodoro status), watchOS complications.

    ## Dependencies
    - Features 1 → 2 → 3 (Foundation chain)
    - Feature 4 depends on 2
    - Features 5-9 depend on 2 and 3 (models + HealthKit)
    - Feature 10 depends on 2 (needs SwiftData models)
    - Features 11-12 can run in parallel after Feature 1
    - Feature 13 depends on 5, 6 (needs Pomodoro + Hydration modules)

    ## Sizing
    - Features 1, 11, 12: **Medium**
    - Features 2, 3, 4, 5, 6, 7, 8, 13: **Large**
    - Features 9, 10: **XL**

    ## Success Criteria
    - All 3 platforms build and run
    - CloudKit sync works across devices
    - HealthKit reads Zepp scale data
    - All 5 health protocol engines enforce rules correctly
    - AI insights generate locally via Apple Intelligence
    - Full Arabic RTL support without layout breaks
features:
    - FEAT-NXS
    - FEAT-CGA
    - FEAT-ELJ
    - FEAT-VDL
    - FEAT-AAO
    - FEAT-BYD
    - FEAT-FWO
    - FEAT-TRE
    - FEAT-LQA
    - FEAT-PCC
    - FEAT-PNQ
    - FEAT-TBZ
    - FEAT-NSH
id: PLAN-MJA
project_id: health-debug
status: in-progress
title: Health Debug v1.0 — Full Platform Build
updated_at: "2026-03-11T23:46:22Z"
version: 2
---

# Health Debug v1.0 — Full Platform Build

# Health Debug v1.0 — Implementation Plan

## Overview
Build a multi-platform Apple ecosystem app (iOS, macOS Menu Bar, watchOS) for personal AI health & metabolic tracking. The app targets a 31-year-old desk-bound software engineer looking to reverse: Gout, High Triglycerides, Fatty Liver, GERD, IBS, Sinusitis, Dehydration, and Caffeine/Sugar dependency.

## Tech Stack
- **Languages:** Swift 6, SwiftUI
- **Data:** SwiftData + CloudKit (cross-device sync)
- **Health:** HealthKit (read/write)
- **Widgets:** WidgetKit
- **AI:** Apple Intelligence (App Intents) + BYOK fallback (Claude/GPT/Gemini)
- **Platforms:** iOS 18+, macOS 15+, watchOS 11+

## Architecture Approach
- **Shared Swift Package** (`HealthDebugKit`) containing all models, business logic, and data layer — consumed by iOS, macOS, and watchOS targets
- **SwiftData models** with CloudKit backing for seamless sync
- **Protocol-oriented design** for health rules engine (Whitelist/Blacklist, timers, alerts)

## Epic Breakdown (13 Features)

### Phase 1: Foundation (Features 1-4)
1. **Project Scaffold & Multi-Platform Setup** (chore) — Xcode project with iOS/macOS/watchOS targets, shared Swift package, SwiftData models, CloudKit container config
2. **SwiftData Models & CloudKit Sync** (feature) — Core data models: WaterLog, MealLog, StandSession, CaffeineLog, SleepConfig, UserProfile with Zepp baseline metrics. CloudKit sync validation.
3. **HealthKit Integration Layer** (feature) — Read/write steps, active energy, heart rate, sleep. Zepp scale metrics ingestion (weight, visceral fat, body water, metabolic age).
4. **User Profile & Onboarding** (feature) — First-launch onboarding capturing baseline data (108kg, visceral fat 14, etc.), target sleep time, work window hours.

### Phase 2: Core Health Modules (Features 5-9)
5. **Epic 1: Desk-Job Hack — 90-Min Pomodoro Stand Tracker** (feature) — Background timer, 90-min intervals, critical alerts on macOS + watchOS, 3-min walk tracking. Insulin sensitivity protocol.
6. **Epic 2: Hydration & Gout Protocol Engine** (feature) — 2.5L daily goal distributed across 10-hour work window, +250ml quick-log on watchOS & macOS menu bar, uric acid flush tracking.
7. **Epic 3: GERD & Sinus System Shutdown Timer** (feature) — 4-hour pre-sleep fasting countdown, "System Shutdown" mode, herbal tea allowance, GERD/Sinus flare-up risk exceptions on food logging.
8. **Epic 4: Focus & Red Bull Deprecation Tracker** (feature) — 90-120 min post-wake caffeine block, clean caffeine transition tracking (Red Bull → Cold Brew/Matcha), fatty liver alerts on sugar caffeine.
9. **Epic 5: Safe Mode Nutrition Logger** (feature) — Boolean safe/unsafe meal tracking with predefined whitelist/blacklist. IBS/GERD/Gout/Fatty Liver trigger warnings. Fast-logging for safe foods.

### Phase 3: AI & Intelligence (Feature 10)
10. **Epic 6: AI Analytics & RAG System** (feature) — Apple Intelligence integration via App Intents, BYOK settings (Claude/GPT/Gemini API keys), local RAG pipeline over SwiftData, 72-hour context retrieval, JSON export to iCloud Drive for CLI analysis.

### Phase 4: UI/UX Polish (Features 11-13)
11. **Theme System — Light/Dark Mode with IDE Aesthetic** (feature) — Semantic colors, neon green accents in dark mode, clinical white/grey in light mode, tech-oriented tone of voice throughout UI.
12. **Localization — Arabic (RTL) & English (LTR)** (feature) — Full i18n with LocalizedStringKey, RTL layout support, SF Arabic fonts, dynamic type scaling.
13. **WidgetKit & Menu Bar Integration** (feature) — iOS widgets (hydration, stand ring, meal status), macOS menu bar app (hydration quick-log, Pomodoro status), watchOS complications.

## Dependencies
- Features 1 → 2 → 3 (Foundation chain)
- Feature 4 depends on 2
- Features 5-9 depend on 2 and 3 (models + HealthKit)
- Feature 10 depends on 2 (needs SwiftData models)
- Features 11-12 can run in parallel after Feature 1
- Feature 13 depends on 5, 6 (needs Pomodoro + Hydration modules)

## Sizing
- Features 1, 11, 12: **Medium**
- Features 2, 3, 4, 5, 6, 7, 8, 13: **Large**
- Features 9, 10: **XL**

## Success Criteria
- All 3 platforms build and run
- CloudKit sync works across devices
- HealthKit reads Zepp scale data
- All 5 health protocol engines enforce rules correctly
- AI insights generate locally via Apple Intelligence
- Full Arabic RTL support without layout breaks
