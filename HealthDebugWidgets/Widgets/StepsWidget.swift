// StepsWidget.swift
// HealthDebugWidgets — home screen widget for daily step count.

import SwiftUI
import WidgetKit

// MARK: - Views

private struct StepsSmallView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double {
        guard snapshot.stepsGoal > 0 else { return 0 }
        return min(snapshot.steps / snapshot.stepsGoal, 1.0)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGreen).opacity(0.25), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(.systemGreen), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(.systemGreen))
                }
            }
            .frame(width: 72, height: 72)

            Text(stepsFormatted(snapshot.steps))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(LocalizedStringKey("Steps"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    private func stepsFormatted(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }
        return String(Int(value))
    }
}

private struct StepsMediumView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double {
        guard snapshot.stepsGoal > 0 else { return 0 }
        return min(snapshot.steps / snapshot.stepsGoal, 1.0)
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGreen).opacity(0.25), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(.systemGreen), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "figure.walk")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(.systemGreen))
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 4) {
                Label(LocalizedStringKey("Steps"), systemImage: "figure.walk")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(stepsFormatted(snapshot.steps))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text(goalText())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(percentageText())
                    .font(.caption2)
                    .foregroundStyle(Color(.systemGreen))
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private func stepsFormatted(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }
        return String(Int(value))
    }

    private func goalText() -> String {
        let goal = Int(snapshot.stepsGoal)
        return "/ \(goal)"
    }

    private func percentageText() -> String {
        let pct = Int(progress * 100)
        return "\(pct)% \(NSLocalizedString("of goal", comment: ""))"
    }
}

private struct StepsLargeView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double {
        guard snapshot.stepsGoal > 0 else { return 0 }
        return min(snapshot.steps / snapshot.stepsGoal, 1.0)
    }

    private var motivationalText: String {
        switch progress {
        case 1.0...:
            return NSLocalizedString("Goal achieved! Great work.", comment: "")
        case 0.75...:
            return NSLocalizedString("Almost there — keep going!", comment: "")
        case 0.5...:
            return NSLocalizedString("Halfway there, stay on track.", comment: "")
        case 0.25...:
            return NSLocalizedString("Good start, keep moving.", comment: "")
        default:
            return NSLocalizedString("Start walking to hit your goal.", comment: "")
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label(LocalizedStringKey("Steps"), systemImage: "figure.walk")
                    .font(.headline)
                    .foregroundStyle(Color(.systemGreen))
                Spacer()
            }

            ZStack {
                Circle()
                    .stroke(Color(.systemGreen).opacity(0.2), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(.systemGreen), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text(stepsFormatted(snapshot.steps))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(LocalizedStringKey("Steps"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey("Goal"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(Int(snapshot.stepsGoal)))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey("of goal"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(.systemGreen))
                }
                Spacer()
            }

            Text(motivationalText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
    }

    private func stepsFormatted(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }
        return String(Int(value))
    }
}

// MARK: - Entry View

struct StepsWidgetEntryView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                StepsSmallView(snapshot: entry.snapshot)
            case .systemMedium:
                StepsMediumView(snapshot: entry.snapshot)
            case .systemLarge:
                StepsLargeView(snapshot: entry.snapshot)
            default:
                StepsSmallView(snapshot: entry.snapshot)
            }
        }
        .ibmFont()
        .containerBackground(for: .widget) { Color(.systemBackground) }
        .widgetURL(URL(string: "healthdebug://steps")!)
    }
}

// MARK: - Widget

struct StepsWidget: Widget {
    static let kind = "StepsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HealthTimelineProvider(cardID: "steps")) { entry in
            StepsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Steps"))
        .description(LocalizedStringKey("Track your daily step count and goal progress."))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Small", as: .systemSmall) {
    StepsWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.steps = 7432; s.stepsGoal = 10000; return s
    }(), cardID: "steps")
}

#Preview("Medium", as: .systemMedium) {
    StepsWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.steps = 7432; s.stepsGoal = 10000; return s
    }(), cardID: "steps")
}

#Preview("Large", as: .systemLarge) {
    StepsWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.steps = 7432; s.stepsGoal = 10000; return s
    }(), cardID: "steps")
}
#endif
