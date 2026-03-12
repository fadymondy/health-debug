// HeartRateWidget.swift
// HealthDebugWidgets — home screen widget for current heart rate.

import SwiftUI
import WidgetKit

// MARK: - Heart Rate Zone

private enum HeartZone {
    case low, normal, elevated, high

    init(bpm: Double) {
        switch bpm {
        case ..<60:  self = .low
        case 60..<100: self = .normal
        case 100..<120: self = .elevated
        default: self = .high
        }
    }

    var label: LocalizedStringKey {
        switch self {
        case .low:      return "Low"
        case .normal:   return "Normal"
        case .elevated: return "Elevated"
        case .high:     return "High"
        }
    }

    var color: Color {
        switch self {
        case .low:      return Color(.systemBlue)
        case .normal:   return Color(.systemGreen)
        case .elevated: return Color(.systemOrange)
        case .high:     return Color(.systemRed)
        }
    }
}

// MARK: - Views

private struct HeartRateSmallView: View {
    let snapshot: WidgetSnapshot

    private var zone: HeartZone { HeartZone(bpm: snapshot.heartRate) }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "heart.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color(.systemRed))

            Text(String(Int(snapshot.heartRate)))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(LocalizedStringKey("bpm"))
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(zone.label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(zone.color)
        }
        .padding(12)
    }
}

private struct HeartRateMediumView: View {
    let snapshot: WidgetSnapshot

    private var zone: HeartZone { HeartZone(bpm: snapshot.heartRate) }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label(LocalizedStringKey("Heart Rate"), systemImage: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(Color(.systemRed))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(Int(snapshot.heartRate)))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(LocalizedStringKey("bpm"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                // Zone color bar
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(zone.color)
                        .frame(width: 4, height: 28)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(zone.label)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(zone.color)
                        Text(zoneDescription())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)

            // Large heart icon with zone color
            ZStack {
                Circle()
                    .fill(zone.color.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "heart.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(zone.color)
            }
        }
        .padding(16)
    }

    private func zoneDescription() -> String {
        switch zone {
        case .low:      return NSLocalizedString("< 60 bpm", comment: "")
        case .normal:   return NSLocalizedString("60–100 bpm", comment: "")
        case .elevated: return NSLocalizedString("100–120 bpm", comment: "")
        case .high:     return NSLocalizedString("> 120 bpm", comment: "")
        }
    }
}

// MARK: - Entry View

struct HeartRateWidgetEntryView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                HeartRateSmallView(snapshot: entry.snapshot)
            case .systemMedium:
                HeartRateMediumView(snapshot: entry.snapshot)
            default:
                HeartRateSmallView(snapshot: entry.snapshot)
            }
        }
        .ibmFont()
        .containerBackground(for: .widget) { Color(.systemBackground) }
        .widgetURL(URL(string: "healthdebug://heartRate")!)
    }
}

// MARK: - Widget

struct HeartRateWidget: Widget {
    static let kind = "HeartRateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HealthTimelineProvider(cardID: "heartRate")) { entry in
            HeartRateWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Heart Rate"))
        .description(LocalizedStringKey("View your current heart rate and zone."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Small", as: .systemSmall) {
    HeartRateWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.heartRate = 72; return s
    }(), cardID: "heartRate")
}

#Preview("Medium", as: .systemMedium) {
    HeartRateWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.heartRate = 108; return s
    }(), cardID: "heartRate")
}
#endif
