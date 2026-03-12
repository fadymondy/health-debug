// WeightWidget.swift
// HealthDebugWidgets — home screen widget for body weight and body fat percentage.

import SwiftUI
import WidgetKit

// MARK: - Views

private struct WeightSmallView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "scalemass.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(.systemBlue))

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(weightFormatted(snapshot.weightKg))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(LocalizedStringKey("kg"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if snapshot.weightBodyFat > 0 {
                Text(bodyFatText(snapshot.weightBodyFat))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
    }

    private func weightFormatted(_ kg: Double) -> String {
        String(format: "%.1f", kg)
    }

    private func bodyFatText(_ pct: Double) -> String {
        String(format: "%.1f%%", pct)
    }
}

private struct WeightMediumView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(.systemBlue).opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color(.systemBlue))
            }

            VStack(alignment: .leading, spacing: 4) {
                Label(LocalizedStringKey("Weight"), systemImage: "scalemass.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(weightFormatted(snapshot.weightKg))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(LocalizedStringKey("kg"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if snapshot.weightBodyFat > 0 {
                    HStack(spacing: 4) {
                        Text(bodyFatText(snapshot.weightBodyFat))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(.systemBlue))
                        Text(LocalizedStringKey("body fat"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(relativeTime(snapshot.updatedAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private func weightFormatted(_ kg: Double) -> String {
        String(format: "%.1f", kg)
    }

    private func bodyFatText(_ pct: Double) -> String {
        String(format: "%.1f%%", pct)
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}

// MARK: - Entry View

struct WeightWidgetEntryView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                WeightSmallView(snapshot: entry.snapshot)
            case .systemMedium:
                WeightMediumView(snapshot: entry.snapshot)
            default:
                WeightSmallView(snapshot: entry.snapshot)
            }
        }
        .containerBackground(for: .widget) { Color(.systemBackground) }
        .widgetURL(URL(string: "healthdebug://weight")!)
    }
}

// MARK: - Widget

struct WeightWidget: Widget {
    static let kind = "WeightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HealthTimelineProvider(cardID: "weight")) { entry in
            WeightWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Weight"))
        .description(LocalizedStringKey("Track your body weight and body fat percentage."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Small", as: .systemSmall) {
    WeightWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.weightKg = 84.5; s.weightBodyFat = 22.3; return s
    }(), cardID: "weight")
}

#Preview("Medium", as: .systemMedium) {
    WeightWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot()
        s.weightKg = 84.5
        s.weightBodyFat = 22.3
        s.updatedAt = Date(timeIntervalSinceNow: -3600)
        return s
    }(), cardID: "weight")
}
#endif
