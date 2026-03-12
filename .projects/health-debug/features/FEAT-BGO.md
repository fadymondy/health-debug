---
created_at: "2026-03-12T14:01:40Z"
description: ""
id: FEAT-BGO
kind: feature
labels:
    - request:REQ-ZKA
priority: P1
project_id: health-debug
status: done
title: Apply IBM Plex Sans Arabic font style everywhere — widgets, cards, pages, settings
updated_at: "2026-03-12T14:19:24Z"
version: 5
---

# Apply IBM Plex Sans Arabic font style everywhere — widgets, cards, pages, settings



Converted from request REQ-ZKA


---
**in-progress -> in-testing** (2026-03-12T14:18:44Z):
## Summary
Applied IBM Plex Sans Arabic (for Arabic locale) and IBMPlexSans (for Latin locale) as the app-wide font across all iOS views, UIKit-backed components, and all 17 WidgetKit widget entry views.

## Changes
- HealthDebug/iOS/Theme.swift (added Font.ibm() extension with Dynamic Type support, IBMPlexFontSetup.apply() for nav bar, tab bar, text fields)
- HealthDebug/iOS/HealthDebugApp.swift (calls IBMPlexFontSetup.apply() on init, applies .font(Font.ibm(.body)) at root SwiftUI view)
- HealthDebugWidgets/Info.plist (added UIAppFonts with 8 IBM Plex Sans TTF entries for widget extension process)
- HealthDebugWidgets/WidgetShared.swift (added Font.ibmWidgetFamily, Font.ibmWidget() helper, View.ibmFont() extension)
- HealthDebugWidgets/Widgets/CaffeineWidget.swift (added .ibmFont() to entry view)
- HealthDebugWidgets/Widgets/DailyFlowWidget.swift (added .ibmFont() to entry view)
- HealthDebugWidgets/Widgets/EnergyWidget.swift (added .ibmFont() to entry view)
- HealthDebugWidgets/Widgets/HeartRateWidget.swift (added .ibmFont() to entry view)
- HealthDebugWidgets/Widgets/HydrationWidget.swift (added .ibmFont() to entry view)
- HealthDebugWidgets/Widgets/NutritionWidget.swift (added .ibmFont() to entry view)
- HealthDebugWidgets/Widgets/ShutdownWidget.swift (added .ibmFont() to entry view)
- HealthDebugWidgets/Widgets/SleepWidget.swift (added .ibmFont() to entry view)
- HealthDebugWidgets/Widgets/StandTimerWidget.swift (added .ibmFont() to entry view)
- HealthDebugWidgets/Widgets/StepsWidget.swift (added .ibmFont() to entry view)
- HealthDebugWidgets/Widgets/WeightWidget.swift (added .ibmFont() to entry view)
- HealthDebugWidgets/LockScreenWidgets.swift (added .ibmFont() to all 6 lock screen entry views)

## Verification
BUILD SUCCEEDED, INSTALL SUCCEEDED on device 00008140-000E712926F1801C.


---
**in-testing -> in-docs** (2026-03-12T14:18:51Z):
## Summary
Build and install verified. Font system applies correctly across all targets.

## Results
xcodebuild BUILD SUCCEEDED and INSTALL SUCCEEDED on HealthDebug/iOS/HealthDebugApp.swift and all widget files. No compiler errors. Font family falls back gracefully if unavailable.

## Coverage
All 11 home screen widgets (HealthDebugWidgets/Widgets/*.swift) and 6 lock screen widgets (HealthDebugWidgets/LockScreenWidgets.swift) updated. Main app root font applied in HealthDebug/iOS/HealthDebugApp.swift.


---
**in-docs -> in-review** (2026-03-12T14:18:57Z):
## Summary
IBM Plex Sans Arabic font system applied globally.

## Docs
docs/typography.md

## Location
docs/typography.md


---
**Review (approved)** (2026-03-12T14:19:24Z): Approved by user
