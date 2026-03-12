# Health Debug

A multi-platform Apple ecosystem app for AI-driven health & metabolic tracking. Built for desk-bound engineers looking to reverse metabolic and digestive conditions through automated protocol enforcement.

## Target Conditions

- Gout & High Uric Acid
- High Triglycerides & Fatty Liver
- GERD (Gastroesophageal Reflux Disease)
- IBS (Irritable Bowel Syndrome)
- Sinusitis
- Dehydration
- Caffeine & Sugar Dependency

## Platforms

| Platform | Minimum Version | Target |
|----------|----------------|--------|
| iOS | 18.0+ | iPhone dashboard |
| macOS | 15.0+ | Menu bar + window app |
| watchOS | 11.0+ | Wrist complications |

## Tech Stack

- **Language:** Swift 6 (strict concurrency)
- **UI:** SwiftUI
- **Data:** SwiftData + CloudKit sync
- **Health:** HealthKit (Zepp scale metrics)
- **Widgets:** WidgetKit (iOS, macOS menu bar, watchOS)
- **AI:** Apple Intelligence (on-device) + BYOK fallback (Claude, GPT, Gemini)

## Architecture

```
HealthDebug/
├── iOS/                    # iOS app target
├── macOS/                  # macOS app target (MenuBarExtra + WindowGroup)
├── watchOS Watch App/      # watchOS app target
└── Shared/                 # Shared assets

Packages/
└── HealthDebugKit/         # Shared Swift package (all platforms)
    ├── Sources/
    └── Tests/
```

All three platform targets consume the shared `HealthDebugKit` Swift package for models, managers, and protocol engines.

## Health Protocol Engines

1. **Desk-Job Hack** — 90-minute Pomodoro stand timer with insulin sensitivity protocol
2. **Hydration & Gout** — 2.5L daily goal distributed across work window with uric acid tracking
3. **GERD & Sinus Shutdown** — 4-hour pre-sleep fasting countdown
4. **Focus & Caffeine** — 90-120 min post-wake caffeine block, Red Bull deprecation tracking
5. **Nutrition Logger** — Safe/unsafe meal tracking with trigger warnings

## Building

Open `HealthDebug.xcodeproj` in Xcode 16+ and select a target:

```bash
# Build the shared package
cd Packages/HealthDebugKit
swift build

# Run tests
swift test
```

## Configuration

- **CloudKit Container:** `iCloud.io.3x1.HealthDebug`
- **App Group:** `group.io.3x1.HealthDebug`
- **Bundle IDs:**
  - iOS: `io.threex1.HealthDebug`
  - macOS: `io.threex1.HealthDebug.mac`
  - watchOS: `io.threex1.HealthDebug.watchkitapp`

## Theme

- **Dark Mode:** Neon green accents on black — terminal/hacker aesthetic
- **Light Mode:** Clinical white/grey with green highlights
- **Localization:** English + Arabic (RTL)

## Documentation

See the [docs/](docs/) folder for detailed documentation:

- [Architecture](docs/architecture.md) — Project structure, platforms, and shared package design
- [Models](docs/models.md) — SwiftData models and CloudKit sync
- [Setup](docs/setup.md) — Build requirements and configuration

## License

All rights reserved.

## Sponsorship

If you find this project useful, consider [sponsoring @fadymondy](https://github.com/sponsors/fadymondy).
