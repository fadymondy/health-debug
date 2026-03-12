# Theme System

## Overview

Health Debug uses an adaptive theme system that automatically adjusts colors for light and dark mode. Dark mode features a neon green IDE/hacker aesthetic; light mode uses a clinical teal/grey palette.

## Color Palette

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `primary` | `#0F6B3A` (forest green) | `#00FF41` (neon green) | Buttons, progress rings, success states |
| `secondary` | `#005580` (deep blue) | `#00D4FF` (cyan) | Labels, secondary cards, info states |
| `accent` | `#157A45` (emerald) | `#39FF85` (mint) | Walking timer, targets, highlights |
| `warning` | `#E8780A` (orange) | `#FF9F0A` (amber) | Behind schedule, caffeine block |
| `danger` | `#D32F2F` (red) | `#FF453A` (coral) | Unsafe foods, dehydration, violations |
| `cardTint` | `#F0F4F8` (cool grey) | `#0A1A12` (dark green) | Card background tints |
| `subtleText` | `#6B7280` (grey) | `#8B9A8F` (sage) | Secondary labels |

## Implementation

All colors use `Color(light:dark:)` which resolves via `UIColor` trait collection:

```swift
static let primary = Color(
    light: Color(hex: 0x0F6B3A),
    dark: Color(hex: 0x00FF41)
)
```

This means:
- No `@Environment(\.colorScheme)` needed in views
- Existing `AppTheme.primary` references work unchanged
- Colors animate smoothly when toggling appearance

## Gradients

| Gradient | Colors | Usage |
|----------|--------|-------|
| `gradient` | primary -> secondary | Brand gradient, splash logo, headings |
| `neonGradient` | primary -> accent | AI insight cards, progress rings |

## Key File

| File | Purpose |
|------|---------|
| `HealthDebug/iOS/Theme.swift` | All color definitions and `Color(light:dark:)` extension |
