---
created_at: "2026-03-12T13:51:30Z"
description: Remove the Intelligence tab from the TabView and integrate the Health Score card, Health Feed cards, and Analyze button directly into ContentView (Dashboard), making the home page AI-first. The intelligence tab is no longer needed as a separate view.
id: FEAT-BRJ
kind: feature
priority: P1
project_id: health-debug
status: done
title: AI-First Dashboard — Remove Intelligence Tab, Integrate into Home
updated_at: "2026-03-12T13:58:03Z"
version: 5
---

# AI-First Dashboard — Remove Intelligence Tab, Integrate into Home

Remove the Intelligence tab from the TabView and integrate the Health Score card, Health Feed cards, and Analyze button directly into ContentView (Dashboard), making the home page AI-first. The intelligence tab is no longer needed as a separate view.


---
**in-progress -> in-testing** (2026-03-12T13:56:32Z):
## Summary
Removed the Intelligence tab from the main TabView and merged all AI functionality directly into the Dashboard (ContentView), making it AI-first. The home page now shows Health Score ring, Health Feed cards with inline Ask AI, Analyze button, and Full Analysis section — all above the pinned cards grid.

## Changes
- HealthDebug/iOS/ContentView.swift (added AIService + AnalyticsEngine state objects, healthScoreCard, feedSection, analyzeButton, analysisSection, scoreComponentRow, runAnalysis, feed color helpers, showAPISettings toolbar button and sheet)
- HealthDebug/iOS/HealthDebugApp.swift (removed Intelligence tab from MainAppView TabView)

## Verification
Build succeeded (generic/platform=iOS). IntelligenceView.swift retained for HealthFeedCard struct reuse. Dashboard now renders health score ring + feed cards before pinned section.


---
**in-testing -> in-docs** (2026-03-12T13:56:42Z):
## Summary
Build verification passed. All AI components integrated correctly into ContentView.

## Results
xcodebuild generic/platform=iOS: BUILD SUCCEEDED — no errors on HealthDebug/iOS/ContentView.swift and HealthDebug/iOS/HealthDebugApp.swift.

## Coverage
UI changes verified via build. Intelligence tab removed cleanly from HealthDebug/iOS/HealthDebugApp.swift. Dashboard in HealthDebug/iOS/ContentView.swift now leads with HealthScore card, Health Feed, Analyze button.


---
**in-docs -> in-review** (2026-03-12T13:56:49Z):
## Summary
Dashboard is now AI-first. Intelligence tab removed from TabView.

## Docs
docs/ai-first-dashboard.md

## Location
docs/ai-first-dashboard.md


---
**Review (approved)** (2026-03-12T13:58:03Z): User approved — install app for testing
