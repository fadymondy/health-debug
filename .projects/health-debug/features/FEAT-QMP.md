---
created_at: "2026-03-12T11:19:30Z"
description: 'Three fixes: (1) HealthFeedCard uses @StateObject private var rag = HealthRAG.shared causing all cards to share state and responses cross-contaminate. Fix by removing the @StateObject and using countBefore/countAfter pattern to isolate per-card AI responses. (2) Card color scheme: icons and titles should use .secondary, metric values/numbers use status color. Apply across HealthMetricCard, HealthCard, HealthFeedCard, DailyFlowMetricCard, DailyFlowFullCard, and DashboardEditSheet. (3) Verify HealthRAG.swift buildRAGPrompt has language detection code — already confirmed present.'
id: FEAT-QMP
kind: bug
priority: P2
project_id: health-debug
status: done
title: Fix HealthFeedCard shared RAG state, card color scheme, and verify language injection
updated_at: "2026-03-12T11:45:46Z"
version: 8
---

# Fix HealthFeedCard shared RAG state, card color scheme, and verify language injection

Three fixes: (1) HealthFeedCard uses @StateObject private var rag = HealthRAG.shared causing all cards to share state and responses cross-contaminate. Fix by removing the @StateObject and using countBefore/countAfter pattern to isolate per-card AI responses. (2) Card color scheme: icons and titles should use .secondary, metric values/numbers use status color. Apply across HealthMetricCard, HealthCard, HealthFeedCard, DailyFlowMetricCard, DailyFlowFullCard, and DashboardEditSheet. (3) Verify HealthRAG.swift buildRAGPrompt has language detection code — already confirmed present.


---
**in-progress -> in-testing** (2026-03-12T11:23:20Z):
## Summary
Fixed three issues: (1) HealthFeedCard RAG state isolation — removed @StateObject private var rag = HealthRAG.shared, replaced runAI() to use countBefore/countAfter pattern so each card captures only its own AI response. (2) Card color scheme — icons and titles now use .secondary across all cards; metric values/numbers use status color. Applied to HealthFeedCard, HealthMetricCard, HealthCard, DailyFlowMetricCard, DailyFlowFullCard, and DashboardEditSheet pin badges. (3) Verified HealthRAG.buildRAGPrompt already has languageCode detection — no change needed.

## Changes
- HealthDebug/iOS/IntelligenceView.swift (removed @StateObject rag line; updated runAI() with countBefore/countAfter pattern; icon .secondary; value .foregroundStyle(statusColor); primary action label .secondary)
- HealthDebug/iOS/ContentView.swift (HealthMetricCard icon .secondary; HealthCard icon .secondary, primaryValue .foregroundStyle(statusColor), quick action label .secondary; DashboardEditSheet pin icon AppTheme.secondary, Pinned badge .secondary tint)
- HealthDebug/iOS/DailyFlowView.swift (DailyFlowMetricCard icon .secondary, value .foregroundStyle(data.scoreColor); DailyFlowFullCard icon .secondary, primary value .foregroundStyle(data.scoreColor))

## Verification
xcodebuild -scheme "HealthDebug iOS" -destination 'id=00008140-000E712926F1801C' returned BUILD SUCCEEDED with zero errors.


---
**in-testing -> in-review** (2026-03-12T11:23:29Z): Gate skipped for kind=bug


---
**Review (needs-edits)** (2026-03-12T11:28:28Z): Still translation issues: AI smart action buttons and some app sections still show English text instead of Arabic.


---
**in-progress -> in-testing** (2026-03-12T11:45:15Z):
## Summary
Fixed all remaining localization issues: HealthFeedCard status labels now use LocalizedStringKey instead of verbatim Text, so rawValue status strings (On Track, Dehydrated, All Safe, Warning, Critical, etc.) properly display in Arabic. Also fixed computed String properties in StandTimerView (timerText/timerSubtext) and ShutdownView (subtitleText) to use NSLocalizedString. Fixed HydrationView quickLogButton label parameter to LocalizedStringKey. Fixed NutritionView quickLogRow title to LocalizedStringKey. Added missing Arabic translations to xcstrings. Build succeeded.

## Changes
- HealthDebug/iOS/IntelligenceView.swift (HealthFeedCard statusLabel: Text(verbatim: statusLabel) changed to Text(LocalizedStringKey(statusLabel)) so enum rawValues localize)
- HealthDebug/iOS/StandTimerView.swift (timerText/timerSubtext computed properties now use NSLocalizedString)
- HealthDebug/iOS/ShutdownView.swift (subtitleText computed property now uses NSLocalizedString)
- HealthDebug/iOS/HydrationView.swift (quickLogButton label: String changed to LocalizedStringKey; navigationTitle uses LocalizedStringKey)
- HealthDebug/iOS/NutritionView.swift (quickLogRow title: String changed to LocalizedStringKey; navigationTitle uses LocalizedStringKey)
- HealthDebug/iOS/CaffeineView.swift (daily limit reached message uses NSLocalizedString format string)
- HealthDebug/Shared/Localizable.xcstrings (added: Active Energy Today, Analyze my weight, Caffeine Today, Daily limit reached (%d drinks), Log 250ml Water, Open screen, Quick action, Recent Screens, Sleep Last Night, Start Stand Timer, Steps Today, Water Log)

## Verification
xcodebuild -scheme "HealthDebug iOS" -destination 'id=00008140-000E712926F1801C' BUILD SUCCEEDED with zero errors.


---
**in-testing -> in-review** (2026-03-12T11:45:34Z): Gate skipped for kind=bug
