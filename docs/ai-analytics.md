# AI Analytics & RAG System

## Overview

The Analytics tab provides AI-powered health insights by aggregating 72 hours of health data and analyzing it with on-device or cloud AI providers.

## Architecture

### Apple Intelligence (Default)
- Uses `FoundationModels` framework (iOS 26+)
- `SystemLanguageModel.default` — ~3B parameter on-device model
- Private, free, works offline
- `LanguageModelSession` with health-specific system instructions

### Cloud Providers (Optional BYOK)
- **Claude** — claude-sonnet-4-5 via Anthropic API
- **GPT** — gpt-4o via OpenAI API
- **Gemini** — gemini-2.0-flash via Google AI API
- API keys stored in iOS Keychain (`SecItemAdd`/`SecItemCopyMatching`)

## Key Files

| File | Purpose |
|------|---------|
| `HealthDebugKit/Health/AIService.swift` | AI provider management, Keychain, API calls |
| `HealthDebugKit/Health/AnalyticsEngine.swift` | 72h context aggregation, JSON export, prompt builder |
| `HealthDebug/iOS/AnalyticsView.swift` | Analytics UI, provider card, API settings sheet |

## Data Flow

1. `AnalyticsEngine.buildContext()` fetches last 72h of WaterLog, MealLog, CaffeineLog, StandSession
2. Builds structured `HealthContext` (Codable) with hydration, nutrition, caffeine, movement, sleep summaries
3. `buildPrompt()` serializes context to JSON and wraps in health optimization instructions
4. `AIService.analyze()` routes to Apple Intelligence or cloud provider
5. Response displayed in insights card with text selection enabled

## Input Validation

All logging views enforce:
- **Hydration**: 30s cooldown, 5000ml daily cap
- **Caffeine**: 60s cooldown, 8 drinks daily cap
- **Nutrition**: 30s cooldown, 12 meals daily cap, 60 char food name limit

## Notifications

Auto-scheduled reminders:
- Hydration: next glass reminder after each log
- Caffeine: block window end notification
- Shutdown: GERD shutdown start alert
- Permission requested on app launch via `UNUserNotificationCenter`

## JSON Export

`AnalyticsEngine.exportJSON()` exports the full `HealthContext` as pretty-printed JSON via `UIActivityViewController` share sheet.
