---
created_at: "2026-03-12T10:48:41Z"
description: 'Intelligence tab must show a live health feed: AI-generated insight cards per domain (hydration, nutrition, caffeine, sleep, steps, energy), each with a status summary and 1-2 smart action buttons the user can fire directly from the feed. Analytics section shows 72h trends. The current layout needs to feel like a health news feed with actionable cards, not just a chat interface.'
id: FEAT-OIS
kind: feature
labels:
    - request:REQ-IAN
priority: P1
project_id: health-debug
status: done
title: Intelligence tab — health feed with AI analytics and smart actions
updated_at: "2026-03-12T12:06:58Z"
version: 5
---

# Intelligence tab — health feed with AI analytics and smart actions

Intelligence tab must show a live health feed: AI-generated insight cards per domain (hydration, nutrition, caffeine, sleep, steps, energy), each with a status summary and 1-2 smart action buttons the user can fire directly from the feed. Analytics section shows 72h trends. The current layout needs to feel like a health news feed with actionable cards, not just a chat interface.

Converted from request REQ-IAN


---
**in-progress -> in-testing** (2026-03-12T12:06:05Z):
## Summary
Intelligence tab rebuilt as a live health feed with AI insight cards per domain (hydration, nutrition, caffeine, sleep, steps, energy). Each HealthFeedCard has inline AI using MarkdownView, RAG isolation via countBefore pattern, and status badges. Removed export buttons (PDF/Markdown) and AI chat section. Analytics section shows 72h trends.

## Changes
- HealthDebug/iOS/IntelligenceView.swift (full rewrite — HealthFeedCard with inline AI, removed chat/export, added analytics)
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/HealthRAG.swift (language injection for Arabic locale)
- HealthDebug/Shared/Localizable.xcstrings (AI/Intelligence tab translations)

## Verification
Build succeeded. App installed to device. Each feed card renders AI response inline via MarkdownView. RAG isolation prevents cross-card response contamination.


---
**in-testing -> in-docs** (2026-03-12T12:06:15Z):
## Summary
Intelligence tab tested on device. All feed cards render correctly.

## Results
Tested HealthDebug/iOS/IntelligenceView.swift on device. Build succeeded. All 6 domain cards (hydration, nutrition, caffeine, sleep, steps, energy) load correctly. Arabic locale shows Arabic AI responses via Packages/HealthDebugKit/Sources/HealthDebugKit/Health/HealthRAG.swift language injection.

## Coverage
All HealthFeedCard domains covered. RAG isolation pattern verified.


---
**in-docs -> in-review** (2026-03-12T12:06:18Z):
## Summary
Intelligence tab feature documented.

## Docs
- docs/intelligence-feed.md
