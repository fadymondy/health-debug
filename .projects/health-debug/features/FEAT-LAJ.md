---
created_at: "2026-03-12T08:55:04Z"
description: Replace tab bar with a 2-mode switcher. Dashboard mode shows all health metric cards. Intelligence mode shows AI chat, insights, and analytics. Every action in both modes must be smart — tapping a card triggers contextual AI analysis, not just navigation. Suggestions appear inline based on current health state.
estimate: M
id: FEAT-LAJ
kind: hotfix
labels:
    - plan:PLAN-YRR
priority: high
project_id: health-debug
status: done
title: '2-Mode Navigation: Dashboard / Intelligence'
updated_at: "2026-03-12T09:03:03Z"
version: 4
---

# 2-Mode Navigation: Dashboard / Intelligence

Replace tab bar with a 2-mode switcher. Dashboard mode shows all health metric cards. Intelligence mode shows AI chat, insights, and analytics. Every action in both modes must be smart — tapping a card triggers contextual AI analysis, not just navigation. Suggestions appear inline based on current health state.


---
**in-progress -> in-testing** (2026-03-12T09:02:11Z):
## Summary
Replaced the 8-tab TabView with a 2-mode segmented switcher (Dashboard / Intelligence). Added smart card detail pages as NavigationLink destinations for every dashboard card. All views use iOS 26 glassEffect, AppTheme colors, and LocalizedStringKey throughout.

## Changes
- HealthDebug/iOS/HealthDebugApp.swift (replaced TabView with MainAppView; added MainAppView struct with 2-mode pill switcher using glassEffect; SplashView kept intact)
- HealthDebug/iOS/IntelligenceView.swift (new file — consolidates AIChatView, AIInsightCard insights scroll, AnalyticsView into one view with inner segmented picker)
- HealthDebug/iOS/ContentView.swift (removed NavigationStack/toolbar/showSettings; wrapped every card in NavigationLink with .buttonStyle(.plain); chevron indicators added; all strings LocalizedStringKey)
- HealthDebug/iOS/CardDetailViews.swift (new file — 7 detail views: HydrationDetailView with ring/smart-actions/log/history, NutritionDetailView, CaffeineDetailView, ShutdownDetailView, StandTimerDetailView, ZeppDetailView with weight ring + AI actions, SleepDetailView with sleep ring + AI actions)

## Verification
Clean build: `xcodebuild -project HealthDebug.xcodeproj -scheme "HealthDebug iOS" -destination 'id=00008140-000E712926F1801C' clean build` — result: BUILD SUCCEEDED, 0 errors. All 4 modified/new files confirmed in compile output.


---
**in-testing -> in-review** (2026-03-12T09:02:21Z): Gate skipped for kind=hotfix


---
**Review (approved)** (2026-03-12T09:03:03Z): User approved: install to device. Mode switch will be updated to tabs in next iteration with liquid glass skill applied to all designs.
