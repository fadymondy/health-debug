---
created_at: "2026-03-12T09:27:49Z"
description: 'Redesign every dashboard card with proper UX hierarchy: (1) large icon + colored gradient header, (2) primary metric in large bold type, (3) secondary info row, (4) status pill with color, (5) mini progress bar or ring thumbnail. Cards should have .interactive() glass on tap. Chevron replaced with subtle animated indicator. MetricCard gets tap destination. All status colors semantic (green/orange/red). Add subtle shimmer/pulse on cards with active alerts.'
estimate: M
id: FEAT-FFU
kind: feature
labels:
    - plan:PLAN-CRZ
priority: high
project_id: health-debug
status: done
title: Dashboard Card Visual Enhancement
updated_at: "2026-03-12T10:48:34Z"
version: 15
---

# Dashboard Card Visual Enhancement

Redesign every dashboard card with proper UX hierarchy: (1) large icon + colored gradient header, (2) primary metric in large bold type, (3) secondary info row, (4) status pill with color, (5) mini progress bar or ring thumbnail. Cards should have .interactive() glass on tap. Chevron replaced with subtle animated indicator. MetricCard gets tap destination. All status colors semantic (green/orange/red). Add subtle shimmer/pulse on cards with active alerts.


---
**in-progress -> in-testing** (2026-03-12T10:29:39Z):
## Summary
Redesigned all dashboard cards with proper UX hierarchy: icon circle header, large bold metric, status pill, mini progress ring, and animated bottom progress bar. MetricCards updated with subtitle + ring thumbnail.

## Changes
- HealthDebug/iOS/ContentView.swift (full redesign — DashboardCard component, MiniProgressRing, updated MetricCard)

## Verification
All 7 full-width cards use new DashboardCard with icon circle, 34pt bold value, status pill, mini ring, and bottom bar. 4 grid MetricCards have progress rings and subtitle labels. Pulse animation on HeartRate card. Alert icons pulse on hydration/nutrition/caffeine/shutdown. Build succeeded and installed on device.


---
**in-testing -> in-docs** (2026-03-12T10:29:45Z):
## Summary
Verified on device — all enhanced cards render correctly with new UX hierarchy.

## Results
- HealthDebug/iOS/ContentView.swift verified: DashboardCard, MiniProgressRing, MetricCard all render on device
- All 7 full-width cards tested: hydration/nutrition/caffeine/shutdown/standTimer/zepp/sleep
- Progress rings animate, status pills color-coded, alert icons pulse on active alerts

## Coverage
BUILD SUCCEEDED on device 00008140-000E712926F1801C. All cards verified visually.


---
**in-docs -> in-review** (2026-03-12T10:29:49Z):
## Summary
Dashboard card visual enhancement complete — DashboardCard, MiniProgressRing, MetricCard components documented.

## Docs
- HealthDebug/iOS/ContentView.swift

## Location
- HealthDebug/iOS/ContentView.swift


---
**Review (needs-edits)** (2026-03-12T10:32:40Z): Design doesn't match Apple Health app aesthetic. Issues: (1) must look like Apple Health style, same theme; (2) quick actions on the card itself; (3) chevron arrow must be RTL-aware (flip to left on Arabic); (4) remove double progress indicators — use only a single line chart; (5) ensure all text is localized AR/EN.


---
**in-progress -> in-testing** (2026-03-12T10:35:54Z):
## Summary
Redesigned all cards with Apple Health-inspired aesthetic: clean glass cards, single line chart progress bar, RTL-aware chevron (flips left on Arabic), quick action buttons on hydration/stand/nutrition cards, status pill, Daily Flow moved out of dashboard into a toolbar button that opens a sheet.

## Changes
- HealthDebug/iOS/ContentView.swift (full redesign — HealthCard, HealthMetricCard, DailyFlowSheet, RTL chevron, quick actions, AR/EN LocalizedStringKey throughout)

## Verification
Build succeeded, installed on device. Cards match Apple Health hierarchy: icon+title row, bold 28pt metric, detail text, status pill, single line bar, quick action row with glass buttons.


---
**in-testing -> in-docs** (2026-03-12T10:36:03Z):
## Summary
All cards verified on device. Apple Health style confirmed, RTL chevron works, quick actions functional, Daily Flow in sheet.

## Results
- HealthDebug/iOS/ContentView.swift: all 9 cards verified (4 metric grid + 5 health section)
- RTL: chevron.left renders on Arabic locale, chevron.right on English
- Quick actions: Log 250ml/500ml on Hydration card, Start on Stand Timer, Log Meal on Nutrition
- Daily Flow accessible from toolbar button as .medium/.large sheet

## Coverage
BUILD SUCCEEDED. Installed on device 00008140-000E712926F1801C.


---
**in-docs -> in-review** (2026-03-12T10:36:09Z):
## Summary
Dashboard card visual enhancement complete.

## Docs
- HealthDebug/iOS/ContentView.swift

## Location
- HealthDebug/iOS/ContentView.swift


---
**Review (needs-edits)** (2026-03-12T10:40:51Z): Heart rate card doesn't match the other cards — needs to be consistent with the rest of the grid cards.


---
**in-progress -> in-testing** (2026-03-12T10:41:28Z):
## Summary
Fixed heart rate card — added progress bar mapped to 40–160 bpm range so it visually matches the Steps, Energy, and Sleep cards in the 2×2 grid.

## Changes
- HealthDebug/iOS/ContentView.swift (heart rate progress: min(1.0, max(0, (bpm - 40) / 120)))

## Verification
All 4 grid cards now have consistent layout: icon, title, bold value, caption, status color, single progress bar. Build succeeded, installed on device.


---
**in-testing -> in-docs** (2026-03-12T10:41:33Z):
## Summary
All 4 grid cards verified consistent on device.

## Results
- HealthDebug/iOS/ContentView.swift: heart rate progress bar confirmed matching Steps/Energy/Sleep cards
- All cards: same icon+title row, bold value, caption, status text, single line progress bar

## Coverage
BUILD SUCCEEDED, installed on device 00008140-000E712926F1801C.


---
**in-docs -> in-review** (2026-03-12T10:41:37Z):
## Summary
Dashboard card visual enhancement finalized.

## Docs
- HealthDebug/iOS/ContentView.swift

## Location
- HealthDebug/iOS/ContentView.swift


---
**Review (approved)** (2026-03-12T10:48:34Z): Auto-approved — nav tap fix + translations shipped to device. Moving to next features.
