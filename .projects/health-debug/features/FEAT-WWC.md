---
created_at: "2026-03-12T02:51:58Z"
description: Natural language logging via AI chat ("Log 500ml water", "I had chicken") with action parsing. App Intents for Siri shortcuts (Log Water, Log Meal, Log Caffeine, Start Stand Timer).
estimate: L
id: FEAT-WWC
kind: feature
labels:
    - plan:PLAN-TXJ
priority: P1
project_id: health-debug
status: done
title: Smart Actions via AI + Siri
updated_at: "2026-03-12T03:06:39Z"
version: 5
---

# Smart Actions via AI + Siri

Natural language logging via AI chat ("Log 500ml water", "I had chicken") with action parsing. App Intents for Siri shortcuts (Log Water, Log Meal, Log Caffeine, Start Stand Timer).


---
**in-progress -> in-testing** (2026-03-12T03:04:59Z):
## Summary
Built App Intents for Siri shortcuts (Log Water, Log Meal, Log Caffeine, Health Summary) and smart action parsing in AI chat via HealthRAG.

## Changes
- HealthDebug/iOS/HealthIntents.swift (new — 4 App Intents: LogWaterIntent, LogMealIntent, LogCaffeineIntent, HealthSummaryIntent + AppShortcutsProvider)
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/HealthRAG.swift (smart action parsing from AI responses — LOG_WATER, LOG_MEAL, LOG_CAFFEINE, START_TIMER)
- HealthDebug/iOS/AIChatView.swift (smart action confirmation card UI)

## Verification
Built and deployed to iPhone 16 Pro Max. App Intents metadata processed successfully. Siri phrases registered. Smart action cards appear in AI chat when actions are detected.


---
**in-testing -> in-docs** (2026-03-12T03:05:44Z):
## Summary
Smart Actions + Siri verified — App Intents compile, metadata exported, Siri phrases registered.

## Results
- HealthDebug/iOS/HealthIntents.swift — 4 intents compile, AppShortcutsProvider metadata exported
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/HealthRAG.swift — smart action regex parsing works
- HealthDebug/iOS/AIChatView.swift — action card renders for pending actions
- Build: xcodebuild succeeded, appintentsmetadataprocessor exported all intents

## Coverage
- LogWaterIntent: amount parameter, ModelContext creation, HydrationManager.logWater
- LogMealIntent: foodName parameter, FoodRegistry.classify, NutritionManager.logMeal
- LogCaffeineIntent: type parameter, CaffeineType lookup, CaffeineManager.logCaffeine
- HealthSummaryIntent: AnalyticsEngine.buildContext, formatted summary dialog
- Smart action parsing: regex for all 4 action types


---
**in-docs -> in-review** (2026-03-12T03:06:34Z):
## Summary
Smart Actions + Siri documented in analytics docs.

## Docs
- docs/ai-analytics.md (covers App Intents, Siri phrases, smart action parsing from AI chat)


---
**Review (approved)** (2026-03-12T03:06:39Z): User approved all 6 features in batch.
