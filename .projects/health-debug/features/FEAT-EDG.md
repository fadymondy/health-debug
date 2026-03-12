---
created_at: "2026-03-12T13:03:49Z"
description: Widgets open the main app home screen instead of the specific widget detail page. Also widgets don't use localized strings (no URL scheme registered in Info.plist, no onOpenURL handler, widget extension has no Localizable.strings).
id: FEAT-EDG
kind: bug
priority: P1
project_id: health-debug
status: done
title: Widget deep links & localization
updated_at: "2026-03-12T13:09:46Z"
version: 4
---

# Widget deep links & localization

Widgets open the main app home screen instead of the specific widget detail page. Also widgets don't use localized strings (no URL scheme registered in Info.plist, no onOpenURL handler, widget extension has no Localizable.strings).


---
**in-progress -> in-testing** (2026-03-12T13:07:01Z):
## Summary
Fixed widget deep links (tapping widget now opens the correct detail screen) and added Localizable.xcstrings to the widget extension bundle so all widget labels are localized.

## Changes
- HealthDebug/iOS/Info.plist (added CFBundleURLTypes with healthdebug:// scheme)
- HealthDebug/iOS/HealthDebugApp.swift (added onOpenURL handler mapping host → HealthScreen, TabView selection binding, removed role: .search to support value: selection)
- HealthDebug/iOS/ContentView.swift (added deepLinkScreen Binding, navPath State, onChange to push HealthScreen into NavigationStack path)
- HealthDebug.xcodeproj/project.pbxproj (added Localizable.xcstrings file ref to widget group and widget resources build phase)


---
**in-testing -> in-review** (2026-03-12T13:07:09Z): Gate skipped for kind=bug


---
**Review (approved)** (2026-03-12T13:09:46Z): Search tab restored with role: .search. Deep links and localization working.
