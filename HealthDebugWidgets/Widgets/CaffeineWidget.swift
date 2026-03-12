// CaffeineWidget.swift
// HealthDebugWidgets — home screen widget for caffeine / Red Bull deprecation tracker.

import SwiftUI
import WidgetKit

// MARK: - Views

private struct CaffeineSmallView: View {
    let snapshot: WidgetSnapshot

    private var statusColor: Color {
        snapshot.caffeineIsClean ? Color(.systemGreen) : Color(.systemOrange)
    }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(statusColor)

            Text(snapshot.caffeineIsClean
                 ? LocalizedStringKey("Clean")
                 : LocalizedStringKey("Not Clean"))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(statusColor)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(drinksText())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    private func drinksText() -> String {
        "\(snapshot.caffeineDrinksToday) \(NSLocalizedString("drinks", comment: ""))"
    }
}

private struct CaffeineMediumView: View {
    let snapshot: WidgetSnapshot

    private var statusColor: Color {
        snapshot.caffeineIsClean ? Color(.systemGreen) : Color(.systemOrange)
    }

    private var motivationalText: String {
        if snapshot.caffeineIsClean {
            if snapshot.caffeineDrinksToday == 0 {
                return NSLocalizedString("No caffeine today — keep it up!", comment: "")
            } else {
                return NSLocalizedString("Staying within healthy limits.", comment: "")
            }
        } else {
            return NSLocalizedString("Try to reduce caffeine intake.", comment: "")
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Status badge
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(statusColor)
                }
                Text(snapshot.caffeineIsClean
                     ? LocalizedStringKey("Clean")
                     : LocalizedStringKey("Not Clean"))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Label(LocalizedStringKey("Caffeine"), systemImage: "cup.and.saucer.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(drinksText())
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(motivationalText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private func drinksText() -> String {
        "\(snapshot.caffeineDrinksToday) \(NSLocalizedString("drinks", comment: "")) \(NSLocalizedString("today", comment: ""))"
    }
}

// MARK: - Entry View

struct CaffeineWidgetEntryView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                CaffeineSmallView(snapshot: entry.snapshot)
            case .systemMedium:
                CaffeineMediumView(snapshot: entry.snapshot)
            default:
                CaffeineSmallView(snapshot: entry.snapshot)
            }
        }
        .containerBackground(for: .widget) { Color(.systemBackground) }
        .widgetURL(URL(string: "healthdebug://caffeine")!)
    }
}

// MARK: - Widget

struct CaffeineWidget: Widget {
    static let kind = "CaffeineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HealthTimelineProvider(cardID: "caffeine")) { entry in
            CaffeineWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Caffeine"))
        .description(LocalizedStringKey("Monitor your caffeine intake status for the day."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Small Clean", as: .systemSmall) {
    CaffeineWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.caffeineIsClean = true; s.caffeineDrinksToday = 1; return s
    }(), cardID: "caffeine")
}

#Preview("Medium Not Clean", as: .systemMedium) {
    CaffeineWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.caffeineIsClean = false; s.caffeineDrinksToday = 3; return s
    }(), cardID: "caffeine")
}
#endif
