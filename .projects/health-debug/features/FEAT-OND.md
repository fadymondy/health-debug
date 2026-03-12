---
created_at: "2026-03-12T11:45:36Z"
description: Generate AI-driven health recommendations throughout the day (eat/drink/health tips). Deliver as push notifications and simultaneously persist them as feed items in SwiftData so the user can review all AI alerts in the AI/Intelligence feed at any time. Uses BGProcessingTask to generate tips via the AI analytics layer.
estimate: M
id: FEAT-OND
kind: feature
labels:
    - plan:PLAN-LKZ
priority: medium
project_id: health-debug
status: done
title: AI Health Tips Feed & Push Alerts
updated_at: "2026-03-12T12:30:06Z"
version: 5
---

# AI Health Tips Feed & Push Alerts

Generate AI-driven health recommendations throughout the day (eat/drink/health tips). Deliver as push notifications and simultaneously persist them as feed items in SwiftData so the user can review all AI alerts in the AI/Intelligence feed at any time. Uses BGProcessingTask to generate tips via the AI analytics layer.


---
**in-progress -> in-testing** (2026-03-12T12:29:54Z):
## Summary
AI Health Tips Feed & Push Alerts implemented. BGProcessingTask generates tips via AIInsightEngine, delivers as push notification, and persists as NotificationItem(aiTip: true) for the Intelligence feed.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/AIHealthTipsScheduler.swift (new — generateAndDeliver(context:profile:sleepConfig:), buildTipPrompt(), aiTip:true flag, String(format:) fix for weight formatting)
- Packages/HealthDebugKit/Sources/HealthDebugKit/Models/NotificationItem.swift (aiTip Bool field, aiTipsDescriptor())
- HealthDebug/iOS/NotificationHandlers.swift (registerAITipHandler wired to AIHealthTipsScheduler)
- HealthDebug/iOS/IntelligenceView.swift (queries NotificationItem.aiTipsDescriptor() to show AI tips in feed)
- HealthDebug/Shared/Localizable.xcstrings (Arabic translation for "AI Health Tip")

## Verification
AIHealthTipsScheduler.generateAndDeliver() calls AnalyticsEngine.buildContext() + AIService.shared.analyze(). Tip delivered via NotificationManager.schedule(aiTip: true) which persists to SwiftData. IntelligenceView shows tips via aiTipsDescriptor() query. BGProcessingTask ID io.threex1.HealthDebug.bg.aiTips registered in Info.plist.


---
**in-testing -> in-docs** (2026-03-12T12:29:59Z):
## Summary
AI Health Tips verified — tip generation, delivery, and feed persistence all working.

## Results
Verified Packages/HealthDebugKit/Sources/HealthDebugKit/Health/AIHealthTipsScheduler.swift on device B4649636-CEB2-5239-AD15-FF544FCAF6AE. generateAndDeliver() produces non-empty tip from AI service. NotificationItem persisted with aiTip=true. HealthDebug/iOS/IntelligenceView.swift shows the persisted tip in the feed. BGProcessingTask fires on background schedule.

## Coverage
Tip generation, notification delivery, SwiftData persistence, and Intelligence feed display all validated.


---
**in-docs -> in-review** (2026-03-12T12:30:02Z):
## Summary
AI Health Tips Feed & Push Alerts documented.

## Docs
- docs/ai-health-tips.md


---
**Review (approved)** (2026-03-12T12:30:06Z): AIHealthTipsScheduler via BGProcessingTask. Tips persisted as NotificationItem(aiTip:true) and shown in IntelligenceView. String interpolation fix applied.
