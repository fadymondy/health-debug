# Ecosystem Expansion — macOS

## macOS App Architecture

The macOS target (`HealthDebug macOS`) is a menu bar + main window app.

### Entry Point
- `HealthDebugMacApp.swift` — `@NSApplicationDelegateAdaptor(AppDelegate.self)`
- `AppDelegate` owns `NSStatusItem` + `NSPopover` (MenuBarView)
- `WindowGroup(id: "main")` with `.defaultLaunchBehavior(.presented)`

### Tab Structure (macOS 26 Liquid Glass capsule)
| Tab | Icon | Content |
|-----|------|---------|
| Feed | list.bullet.rectangle.portrait.fill | MacDashboardView |
| Insights | chart.line.uptrend.xyaxis | MacAnalyticsDetailView |
| Awareness | brain.head.profile.fill | MacAIChatView |
| Settings | gearshape.fill | MacProfileView / MacCreateProfileView |
| Search | magnifyingglass (role: .search) | MacSearchView |

### Key Files
- `MacContentView.swift` — root TabView + all detail views
- `MacTheme.swift` — AppTheme using NSColor (no UIKit)
- `MacMarkdownView.swift` — pure SwiftUI markdown renderer
- `MenuBarView.swift` — live metrics in popover

### Profile Auto-Creation
`ensureProfile()` in MacContentView inserts a default `UserProfile` + `SleepConfig` on first launch if the SwiftData store is empty.
