# Localization

## Supported Languages

| Language | Code | Direction | Status |
|----------|------|-----------|--------|
| English | `en` | LTR | Development language |
| Arabic | `ar` | RTL | Fully translated |

## Implementation

### String Catalog

All localized strings are in `HealthDebug/Shared/Localizable.xcstrings` (Xcode 15+ format). This file is shared across iOS, macOS, and watchOS targets.

SwiftUI `Text("string literal")` automatically uses `LocalizedStringKey`, which looks up translations in the string catalog. For dynamic strings from enums or arrays (e.g. `type.rawValue`, food names), views use `Text(LocalizedStringKey(item))` explicitly.

### RTL Support

All views use `.leading`/`.trailing` alignment (never `.left`/`.right`), so SwiftUI automatically flips layouts for Arabic and other RTL languages.

### Predefined Data

Predefined data strings (food names, caffeine types, drink names) are translated via `Text(LocalizedStringKey(item))`:

| Data | Example |
|------|---------|
| CaffeineType rawValues | Red Bull → ريد بول, Matcha → ماتشا, Green Tea → شاي أخضر |
| allowedDrinks | Water → الماء, Chamomile Tea → شاي بابونج, Anise Tea → شاي يانسون |
| Safe food names | Grilled Chicken Breast → صدر دجاج مشوي, Oats → شوفان |
| TriggerType | IBS/GERD → القولون/ارتجاع المريء, Gout → النقرس, Fatty Liver → الكبد الدهني |
| Status enums | On Track → على المسار, All Safe → كل شيء آمن, Clean → نظيف |

### AI Locale Detection

`AIInsightEngine` checks `Locale.current.language.languageCode`. When `ar`, it appends `"Respond in Arabic (العربية)."` to every domain prompt. Works for all providers (Apple Intelligence, Claude, GPT, Gemini).

### Coverage

190+ strings translated across all screens:

| Screen | String Count |
|--------|-------------|
| Dashboard (ContentView) | ~25 |
| Hydration | ~15 |
| Nutrition | ~30 |
| Caffeine | ~25 |
| Shutdown | ~20 |
| Stand Timer | ~15 |
| AI Chat | ~10 |
| Analytics | ~15 |
| Onboarding | ~20 |
| Settings | ~10 |
| AI Insight Card | ~3 |
| Predefined data | ~60 |

### Adding a New Language

1. Open `HealthDebug/Shared/Localizable.xcstrings` in Xcode
2. Click the "+" button in the languages column
3. Select the new language
4. Translate each string

### Key File

| File | Purpose |
|------|---------|
| `HealthDebug/Shared/Localizable.xcstrings` | All localized strings (English + Arabic) |
