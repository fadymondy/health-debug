// SleepWidget.swift
// HealthDebugWidgets — home screen widget for sleep duration and quality.

import SwiftUI
import WidgetKit

// MARK: - Sleep Quality

private enum SleepQuality {
    case poor, fair, good

    init(hours: Double) {
        if hours >= 7 { self = .good }
        else if hours >= 6 { self = .fair }
        else { self = .poor }
    }

    var label: LocalizedStringKey {
        switch self {
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        }
    }

    var color: Color {
        switch self {
        case .poor: return Color(.systemRed)
        case .fair: return Color(.systemOrange)
        case .good: return Color(.systemPurple)
        }
    }
}

// MARK: - Views

private struct SleepSmallView: View {
    let snapshot: WidgetSnapshot

    private var quality: SleepQuality { SleepQuality(hours: snapshot.sleepHours) }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color(.systemPurple))

            Text(hoursFormatted(snapshot.sleepHours))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(LocalizedStringKey("hours"))
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(quality.label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(quality.color)
        }
        .padding(12)
    }

    private func hoursFormatted(_ h: Double) -> String {
        String(format: "%.1f", h)
    }
}

private struct SleepMediumView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double {
        guard snapshot.sleepGoal > 0 else { return 0 }
        return min(snapshot.sleepHours / snapshot.sleepGoal, 1.0)
    }
    private var quality: SleepQuality { SleepQuality(hours: snapshot.sleepHours) }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label(LocalizedStringKey("Sleep"), systemImage: "moon.stars.fill")
                    .font(.caption)
                    .foregroundStyle(Color(.systemPurple))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", snapshot.sleepHours))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(LocalizedStringKey("hours"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemPurple).opacity(0.2))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(quality.color)
                            .frame(width: geo.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)

                Text(goalText())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            // Quality badge
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(quality.color.opacity(0.12))
                        .frame(width: 60, height: 60)
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(quality.color)
                }
                Text(quality.label)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(quality.color)
            }
        }
        .padding(16)
    }

    private func goalText() -> String {
        let goal = snapshot.sleepGoal
        return "\(NSLocalizedString("Goal", comment: "")): \(String(format: "%.0f", goal))h"
    }
}

// MARK: - Entry View

struct SleepWidgetEntryView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SleepSmallView(snapshot: entry.snapshot)
            case .systemMedium:
                SleepMediumView(snapshot: entry.snapshot)
            default:
                SleepSmallView(snapshot: entry.snapshot)
            }
        }
        .ibmFont()
        .containerBackground(for: .widget) { Color(.systemBackground) }
        .widgetURL(URL(string: "healthdebug://sleep")!)
    }
}

// MARK: - Widget

struct SleepWidget: Widget {
    static let kind = "SleepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HealthTimelineProvider(cardID: "sleep")) { entry in
            SleepWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Sleep"))
        .description(LocalizedStringKey("Track your sleep duration and quality rating."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Small", as: .systemSmall) {
    SleepWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.sleepHours = 6.5; s.sleepGoal = 8; return s
    }(), cardID: "sleep")
}

#Preview("Medium", as: .systemMedium) {
    SleepWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.sleepHours = 7.2; s.sleepGoal = 8; return s
    }(), cardID: "sleep")
}
#endif
