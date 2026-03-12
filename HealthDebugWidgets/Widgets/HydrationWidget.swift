// HydrationWidget.swift
// HealthDebugWidgets — home screen widget for daily hydration tracking.

import SwiftUI
import WidgetKit

// MARK: - Views

private struct HydrationSmallView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double {
        guard snapshot.hydrationGoalMl > 0 else { return 0 }
        return min(Double(snapshot.hydrationMl) / Double(snapshot.hydrationGoalMl), 1.0)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color(.systemBlue).opacity(0.25), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(.systemBlue), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "drop.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(.systemBlue))
            }
            .frame(width: 64, height: 64)

            Text(mlFormatted(snapshot.hydrationMl))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(LocalizedStringKey("ml"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    private func mlFormatted(_ ml: Int) -> String {
        if ml >= 1000 {
            return String(format: "%.1fL", Double(ml) / 1000)
        }
        return "\(ml)"
    }
}

private struct HydrationMediumView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double {
        guard snapshot.hydrationGoalMl > 0 else { return 0 }
        return min(Double(snapshot.hydrationMl) / Double(snapshot.hydrationGoalMl), 1.0)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Ring
            ZStack {
                Circle()
                    .stroke(Color(.systemBlue).opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(.systemBlue), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(.systemBlue))
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(.systemBlue))
                }
            }
            .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 4) {
                Label(LocalizedStringKey("Hydration"), systemImage: "drop.fill")
                    .font(.caption)
                    .foregroundStyle(Color(.systemBlue))

                Text(mlFormatted(snapshot.hydrationMl))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text(LocalizedStringKey("ml"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(goalText())
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(percentageText())
                    .font(.caption2)
                    .foregroundStyle(Color(.systemBlue))
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private func mlFormatted(_ ml: Int) -> String {
        if ml >= 1000 {
            return String(format: "%.1fL", Double(ml) / 1000)
        }
        return "\(ml)"
    }

    private func goalText() -> String {
        let goal = snapshot.hydrationGoalMl
        let goalStr = goal >= 1000 ? String(format: "%.1fL", Double(goal) / 1000) : "\(goal)ml"
        return "\(NSLocalizedString("Goal", comment: "")): \(goalStr)"
    }

    private func percentageText() -> String {
        "\(Int(progress * 100))% \(NSLocalizedString("of goal", comment: ""))"
    }
}

// MARK: - Entry View

struct HydrationWidgetEntryView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                HydrationSmallView(snapshot: entry.snapshot)
            case .systemMedium:
                HydrationMediumView(snapshot: entry.snapshot)
            default:
                HydrationSmallView(snapshot: entry.snapshot)
            }
        }
        .containerBackground(for: .widget) { Color(.systemBackground) }
        .widgetURL(URL(string: "healthdebug://hydration")!)
    }
}

// MARK: - Widget

struct HydrationWidget: Widget {
    static let kind = "HydrationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HealthTimelineProvider(cardID: "hydration")) { entry in
            HydrationWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Hydration"))
        .description(LocalizedStringKey("Track your daily water intake and hydration goal."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Small", as: .systemSmall) {
    HydrationWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.hydrationMl = 1200; s.hydrationGoalMl = 2500; return s
    }(), cardID: "hydration")
}

#Preview("Medium", as: .systemMedium) {
    HydrationWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.hydrationMl = 1750; s.hydrationGoalMl = 2500; return s
    }(), cardID: "hydration")
}
#endif
