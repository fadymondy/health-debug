---
created_at: "2026-03-12T11:31:08Z"
description: ""
id: FEAT-AKT
kind: bug
priority: P1
project_id: health-debug
status: done
title: Fix all missing Arabic translations — wrap hardcoded strings with LocalizedStringKey
updated_at: "2026-03-12T11:46:51Z"
version: 4
---

# Fix all missing Arabic translations — wrap hardcoded strings with LocalizedStringKey




---
**in-progress -> in-testing** (2026-03-12T11:46:11Z):
## Summary
Fixed all missing Arabic translations across all iOS view files. Wrapped hardcoded strings in computed String properties with NSLocalizedString, changed quickLogButton/quickLogRow parameters from String to LocalizedStringKey, fixed HealthFeedCard verbatim Text to use LocalizedStringKey. Added 12 new Arabic translation keys to Localizable.xcstrings.

## Changes
- HealthDebug/iOS/StandTimerView.swift (timerText returns NSLocalizedString for Stand!; timerSubtext returns NSLocalizedString for Tap to start/Until next stand break/Take a 3-min walk/Keep walking; sessions count uses NSLocalizedString)
- HealthDebug/iOS/CaffeineView.swift (daily limit reached message consolidated to NSLocalizedString format string Daily limit reached (%d drinks))
- HealthDebug/iOS/ShutdownView.swift (subtitleText computed String now uses NSLocalizedString for Until shutdown/Until sleep/Until sleep (violated))
- HealthDebug/iOS/HydrationView.swift (quickLogButton label: String changed to LocalizedStringKey for Small/Glass/Bottle; navigationTitle uses LocalizedStringKey)
- HealthDebug/iOS/NutritionView.swift (quickLogRow title: String changed to LocalizedStringKey for Proteins/Carbs/Fats; safe/unsafe inline count uses NSLocalizedString; navigationTitle uses LocalizedStringKey)
- HealthDebug/iOS/IntelligenceView.swift (HealthFeedCard statusLabel Text(verbatim:) changed to Text(LocalizedStringKey()) so all enum rawValue status badges localize)
- HealthDebug/Shared/Localizable.xcstrings (added 12 new keys with Arabic: Active Energy Today/الطاقة النشطة اليوم, Analyze my weight/تحليل وزني, Caffeine Today/الكافيين اليوم, Daily limit reached (%d drinks)/تم الوصول للحد اليومي (%d مشروبات), Log 250ml Water/سجّل 250مل ماء, Open screen/فتح الشاشة, Quick action/إجراء سريع, Recent Screens/الشاشات الأخيرة, Sleep Last Night/النوم الليلة الماضية, Start Stand Timer/بدء مؤقت الوقوف, Steps Today/الخطوات اليوم, Water Log/سجل الماء)

## Verification
xcodebuild -scheme HealthDebug iOS -destination id=00008140-000E712926F1801C BUILD SUCCEEDED with zero errors.


---
**in-testing -> in-review** (2026-03-12T11:46:40Z): Gate skipped for kind=bug
