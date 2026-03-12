// DailyFlowWidget.swift
// HealthDebugWidgets — home screen widget for Daily Flow score (6-point daily goal tracker).

import SwiftUI
import WidgetKit

// MARK: - Flow Goal Labels

private let flowGoalKeys: [LocalizedStringKey] = [
    "Morning Hydration",
    "Meals Logged",
    "Stand Sessions",
    "Caffeine Clean",
    "Shutdown",
    "Sleep Quality"
]

// MARK: - Score Color

private func flowColor(score: Int) -> Color {
    if score >= 5 { return Color(.systemGreen) }
    if score >= 3 { return Color(.systemOrange) }
    return Color(.systemRed)
}

// MARK: - Views

private struct DailyFlowSmallView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double {
        guard snapshot.dailyFlowTotal > 0 else { return 0 }
        return min(Double(snapshot.dailyFlowScore) / Double(snapshot.dailyFlowTotal), 1.0)
    }

    private var color: Color { flowColor(score: snapshot.dailyFlowScore) }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.25), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "checklist")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: 64, height: 64)

            Text("\(snapshot.dailyFlowScore)/\(snapshot.dailyFlowTotal)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(LocalizedStringKey("Daily Flow"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }
}

private struct DailyFlowMediumView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double {
        guard snapshot.dailyFlowTotal > 0 else { return 0 }
        return min(Double(snapshot.dailyFlowScore) / Double(snapshot.dailyFlowTotal), 1.0)
    }

    private var color: Color { flowColor(score: snapshot.dailyFlowScore) }

    var body: some View {
        HStack(spacing: 16) {
            // Ring
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 1) {
                    Text("\(snapshot.dailyFlowScore)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("/\(snapshot.dailyFlowTotal)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 4) {
                Label(LocalizedStringKey("Daily Flow"), systemImage: "checklist")
                    .font(.caption)
                    .foregroundStyle(color)

                // 6 dots
                HStack(spacing: 5) {
                    ForEach(0..<snapshot.dailyFlowTotal, id: \.self) { index in
                        Circle()
                            .fill(index < snapshot.dailyFlowScore ? color : Color(.systemGray).opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }

                Text(percentageText())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private func percentageText() -> String {
        let pct = Int(progress * 100)
        return "\(pct)% \(NSLocalizedString("of goal", comment: ""))"
    }
}

private struct DailyFlowLargeView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double {
        guard snapshot.dailyFlowTotal > 0 else { return 0 }
        return min(Double(snapshot.dailyFlowScore) / Double(snapshot.dailyFlowTotal), 1.0)
    }

    private var color: Color { flowColor(score: snapshot.dailyFlowScore) }

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                Label(LocalizedStringKey("Daily Flow"), systemImage: "checklist")
                    .font(.headline)
                    .foregroundStyle(color)
                Spacer()
                Text("\(snapshot.dailyFlowScore)/\(snapshot.dailyFlowTotal)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }

            // Ring
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(LocalizedStringKey("Daily Flow"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)

            // Goal rows — 6 items
            VStack(spacing: 6) {
                ForEach(0..<min(flowGoalKeys.count, snapshot.dailyFlowTotal), id: \.self) { index in
                    HStack(spacing: 10) {
                        Image(systemName: index < snapshot.dailyFlowScore
                              ? "checkmark.circle.fill"
                              : "circle")
                            .foregroundStyle(index < snapshot.dailyFlowScore ? color : Color(.systemGray).opacity(0.5))
                            .font(.system(size: 16))
                        Text(flowGoalKeys[index])
                            .font(.subheadline)
                            .foregroundStyle(index < snapshot.dailyFlowScore ? .primary : .secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Entry View

struct DailyFlowWidgetEntryView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                DailyFlowSmallView(snapshot: entry.snapshot)
            case .systemMedium:
                DailyFlowMediumView(snapshot: entry.snapshot)
            case .systemLarge:
                DailyFlowLargeView(snapshot: entry.snapshot)
            default:
                DailyFlowSmallView(snapshot: entry.snapshot)
            }
        }
        .containerBackground(for: .widget) { Color(.systemBackground) }
        .widgetURL(URL(string: "healthdebug://dailyFlow")!)
    }
}

// MARK: - Widget

struct DailyFlowWidget: Widget {
    static let kind = "DailyFlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HealthTimelineProvider(cardID: "dailyFlow")) { entry in
            DailyFlowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Daily Flow"))
        .description(LocalizedStringKey("Track your 6 daily health goals and overall flow score."))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Small", as: .systemSmall) {
    DailyFlowWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.dailyFlowScore = 4; s.dailyFlowTotal = 6; return s
    }(), cardID: "dailyFlow")
}

#Preview("Medium", as: .systemMedium) {
    DailyFlowWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.dailyFlowScore = 3; s.dailyFlowTotal = 6; return s
    }(), cardID: "dailyFlow")
}

#Preview("Large", as: .systemLarge) {
    DailyFlowWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.dailyFlowScore = 5; s.dailyFlowTotal = 6; return s
    }(), cardID: "dailyFlow")
}
#endif
