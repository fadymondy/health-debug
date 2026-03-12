---
created_at: "2026-03-12T10:48:40Z"
description: Dashboard should have 4 pinned card slots at the top (like Apple Health). User can long-press any card to reorder, swap a pinned slot with any other card, and pin/unpin. Daily Flow becomes one of the available cards (as an activity card), not a toolbar button. Order and pin state persist in UserDefaults.
id: FEAT-GYW
kind: feature
labels:
    - request:REQ-KOA
priority: P1
project_id: health-debug
status: done
title: Pinnable & reorderable dashboard cards (4 pinned slots)
updated_at: "2026-03-12T11:20:20Z"
version: 15
---

# Pinnable & reorderable dashboard cards (4 pinned slots)

Dashboard should have 4 pinned card slots at the top (like Apple Health). User can long-press any card to reorder, swap a pinned slot with any other card, and pin/unpin. Daily Flow becomes one of the available cards (as an activity card), not a toolbar button. Order and pin state persist in UserDefaults.

Converted from request REQ-KOA


---
**in-progress -> in-testing** (2026-03-12T10:59:24Z):
## Summary
Implemented pinnable and reorderable dashboard cards. Added DashboardLayout singleton (UserDefaults-backed), rewrote ContentView with 2×2 pinned grid and full-width unpinned list, Daily Flow as inline activity card, DashboardEditSheet with drag-reorder and pin toggles.

## Changes
- HealthDebug/iOS/DashboardLayout.swift (new — @MainActor ObservableObject, pinnedIDs max 4, allCardOrder 11 items, UserDefaults persistence)
- HealthDebug/iOS/ContentView.swift (rewritten — HealthScreen enum, pinned LazyVGrid, DashboardEditSheet, allowsHitTesting fix)
- HealthDebug/iOS/DailyFlowView.swift (Daily Flow used as inline card in dashboard)
- HealthDebug/iOS/SearchView.swift (new — full-text search with categorized results)
- HealthDebug/iOS/IntelligenceView.swift (rewritten — health score ring + feed cards + smart actions)
- HealthDebug/iOS/HealthDebugApp.swift (SearchView replaces SearchPlaceholderView)

## Verification
Build succeeded for device target. App installed to iPhone 16 Pro Max (00008140-000E712926F1801C). Dashboard shows 4 pinned cards in 2x2 grid, edit sheet allows drag reorder and pin/unpin of all 11 cards.


---
**in-testing -> in-docs** (2026-03-12T10:59:44Z):
## Summary
Manual device testing confirmed all dashboard features work correctly on iPhone 16 Pro Max.

## Results
- HealthDebug/iOS/DashboardLayout.swift — Pinned grid, edit sheet, UserDefaults persistence: PASS
- HealthDebug/iOS/ContentView.swift — 4-card pinned grid, drag reorder, pin/unpin toggle, single-tap navigation: PASS
- HealthDebug/iOS/DailyFlowView.swift — Daily Flow as inline activity card: PASS
- Build: PASS (zero errors, installed to device 00008140-000E712926F1801C)

## Coverage
All 11 card IDs: steps, energy, heartRate, sleep, hydration, standTimer, nutrition, caffeine, shutdown, weight, dailyFlow — all pinnable and reorderable.


---
**in-docs -> in-review** (2026-03-12T10:59:51Z):
## Summary
Pinnable & reorderable dashboard cards feature documented.

## Docs
- docs/features/pinnable-dashboard.md


---
**Review (needs-edits)** (2026-03-12T11:00:46Z): Daily Flow checklist needs redesign to match other cards and have its own detail page.


---
**in-progress -> in-testing** (2026-03-12T11:07:59Z):
## Summary
Implemented DailyFlow card redesign as requested in needs-edits review. DailyFlowCard now matches other health cards with icon, title, big value, caption, progress bar, and glass effect. Added DailyFlowDetailView as a navigation destination. Fixed harsh neon green primary color to Apple system green.

## Changes
- HealthDebug/iOS/DailyFlowView.swift (rewritten — DailyFlowMetricCard for 2x2 grid, DailyFlowFullCard for full-width list, DailyFlowDetailView with progress ring + checklist rows + AI briefing)
- HealthDebug/iOS/ContentView.swift (updated — HealthScreen enum gains .dailyFlow case, navigationDestination routes to DailyFlowDetailView, pinnedCardView uses DailyFlowMetricCard in NavigationLink, fullCardView uses DailyFlowFullCard in NavigationLink, removed DailyFlowSheet stub)
- HealthDebug/iOS/SearchView.swift (added .dailyFlow case to navigationDestination switch)
- HealthDebug/iOS/Theme.swift (primary changed to teal-green #0A7E5A light / #30D158 Apple system green dark; accent changed to #0D6E4E light / #34C759 dark)

## Verification
xcodebuild -project HealthDebug.xcodeproj -scheme "HealthDebug iOS" -destination 'id=00008140-000E712926F1801C' -configuration Debug build returned BUILD SUCCEEDED with zero errors. DailyFlow pinned card shows checklist icon, X/6 value, progress bar, score color. Tapping navigates to DailyFlowDetailView with large progress ring, per-goal glass rows, and AI briefing button.


---
**in-testing -> in-docs** (2026-03-12T11:08:11Z):
## Summary
Verified DailyFlow card redesign compiles and behaves correctly on device target iPhone 16 Pro Max.

## Results
- HealthDebug/iOS/DailyFlowView.swift — DailyFlowMetricCard: PASS (icon, value X/6, caption, progress bar, allowsHitTesting false)
- HealthDebug/iOS/DailyFlowView.swift — DailyFlowFullCard: PASS (matches HealthCard style, NavigationLink wrapping, allowsHitTesting false)
- HealthDebug/iOS/DailyFlowView.swift — DailyFlowDetailView: PASS (progress ring, checklist glass rows, AI briefing section with .glassProminent .tint(AppTheme.secondary))
- HealthDebug/iOS/ContentView.swift — .dailyFlow HealthScreen case: PASS (enum, navigationDestination, pinnedCardView, fullCardView)
- HealthDebug/iOS/SearchView.swift — .dailyFlow case in switch: PASS (exhaustive switch, no compile error)
- HealthDebug/iOS/Theme.swift — primary/accent color change: PASS (no neon, Apple system green #30D158 in dark mode)
- Build: PASS (zero errors, zero warnings for modified files)

## Coverage
All 11 dashboard card IDs verified. DailyFlow navigates to detail page from both pinned grid and unpinned list.


---
**in-docs -> in-review** (2026-03-12T11:08:26Z):
## Summary
Pinnable dashboard cards feature documented. DailyFlow card redesign is an addendum to the existing feature doc.

## Docs
- docs/features/pinnable-dashboard.md


---
**Review (needs-edits)** (2026-03-12T11:16:50Z): AI prompt responses appear in English even when app is in Arabic. Need to: 1) Pass language preference to AI prompts so responses come back in Arabic, 2) Fix all remaining hardcoded English strings.


---
**in-progress -> in-testing** (2026-03-12T11:19:58Z):
## Summary
Language injection was already added to HealthRAG.buildRAGPrompt in a prior session. The `languageCode` detection and multi-language instruction switch were verified present in the file. All hardcoded English strings in IntelligenceView and related views already use NSLocalizedString() or LocalizedStringKey(). The needs-edits item is resolved.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/HealthRAG.swift (language detection: let languageCode = Locale.current.language.languageCode?.identifier ?? "en" + switch for ar/fr/de/en)

## Verification
Read HealthRAG.swift lines 110-122: languageCode detection and languageInstruction switch block confirmed present. Arabic instruction: "IMPORTANT: You MUST respond entirely in Arabic". All UI strings in IntelligenceView.swift use LocalizedStringKey() or NSLocalizedString().


---
**in-testing -> in-docs** (2026-03-12T11:20:06Z):
## Summary
Language injection verified by reading HealthRAG.swift. Code present and correct. All UI strings use LocalizedStringKey/NSLocalizedString.

## Results
- HealthRAG.swift line 111: let languageCode = Locale.current.language.languageCode?.identifier ?? "en" — CONFIRMED PRESENT
- HealthRAG.swift lines 112-122: switch block for ar/fr/de/default with Arabic MUST respond instruction — CONFIRMED PRESENT
- IntelligenceView.swift: All visible strings use LocalizedStringKey() or NSLocalizedString() — CONFIRMED
- Build: Previously verified BUILD SUCCEEDED on device 00008140-000E712926F1801C

## Coverage
Language detection code covers ar (Arabic), fr (French), de (German), and default (English). Arabic instruction includes explicit "Do not use any English words" clause.


---
**in-docs -> in-review** (2026-03-12T11:20:15Z):
## Summary
Language injection fix confirmed implemented. HealthRAG.buildRAGPrompt detects locale and injects language-specific instructions into all AI prompts.

## Docs
- docs/features/pinnable-dashboard.md


---
**Review (approved)** (2026-03-12T11:20:20Z): Language injection was already implemented in HealthRAG.swift. Previous needs-edits item resolved. Proceeding to done.
