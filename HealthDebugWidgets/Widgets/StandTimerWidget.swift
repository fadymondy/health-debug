// StandTimerWidget.swift
// HealthDebugWidgets — home screen widget for the 90-min Pomodoro stand timer.

import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Phase Display

private extension String {
    /// Maps pomodoroPhase raw string to a localized display label.
    var phaseDisplayKey: LocalizedStringKey {
        switch self {
        case "work":       return "Focus"
        case "shortBreak": return "Break"
        case "longBreak":  return "Long Break"
        case "standAlert": return "Stand!"
        default:           return "Ready"   // "idle" or unknown
        }
    }

    var phaseColor: Color {
        switch self {
        case "work":       return Color(.systemTeal)
        case "shortBreak": return Color(.systemGreen)
        case "longBreak":  return Color(.systemBlue)
        case "standAlert": return Color(.systemOrange)
        default:           return Color(.systemGray)
        }
    }
}

// MARK: - Views

private struct StandTimerSmallView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(snapshot.pomodoroPhase.phaseColor)

            Text("\(snapshot.pomodoroCompleted)/\(snapshot.pomodoroTarget)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(LocalizedStringKey("sessions"))
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(snapshot.pomodoroPhase.phaseDisplayKey)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(snapshot.pomodoroPhase.phaseColor)
        }
        .padding(12)
    }
}

private struct StandTimerMediumView: View {
    let snapshot: WidgetSnapshot

    private var isIdle: Bool { snapshot.pomodoroPhase == "idle" }
    private var isWorking: Bool { snapshot.pomodoroPhase == "work" || snapshot.pomodoroPhase == "standAlert" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(LocalizedStringKey("Stand Timer"), systemImage: "timer")
                    .font(.caption)
                    .foregroundStyle(Color(.systemTeal))
                Spacer()
                Text(snapshot.pomodoroPhase.phaseDisplayKey)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(snapshot.pomodoroPhase.phaseColor)
            }

            // Session dots
            HStack(spacing: 6) {
                ForEach(0..<snapshot.pomodoroTarget, id: \.self) { index in
                    Circle()
                        .fill(index < snapshot.pomodoroCompleted
                              ? Color(.systemTeal)
                              : Color(.systemGray).opacity(0.3))
                        .frame(width: 14, height: 14)
                }
                Spacer(minLength: 0)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(snapshot.pomodoroCompleted)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("/ \(snapshot.pomodoroTarget)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(LocalizedStringKey("sessions"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                // Context-aware action button
                if isIdle {
                    Button(intent: StartFocusIntent()) {
                        Label(LocalizedStringKey("Start"), systemImage: "play.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(Color(.systemTeal))
                    }
                    .buttonStyle(.plain)
                } else if isWorking {
                    Button(intent: TakeBreakIntent()) {
                        Label(LocalizedStringKey("Break"), systemImage: "pause.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(Color(.systemOrange))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Entry View

struct StandTimerWidgetEntryView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                StandTimerSmallView(snapshot: entry.snapshot)
            case .systemMedium:
                StandTimerMediumView(snapshot: entry.snapshot)
            default:
                StandTimerSmallView(snapshot: entry.snapshot)
            }
        }
        .ibmFont()
        .containerBackground(for: .widget) { Color(.systemBackground) }
        .widgetURL(URL(string: "healthdebug://standTimer")!)
    }
}

// MARK: - Widget

struct StandTimerWidget: Widget {
    static let kind = "StandTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HealthTimelineProvider(cardID: "standTimer")) { entry in
            StandTimerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Stand Timer"))
        .description(LocalizedStringKey("Track your Pomodoro stand sessions and current phase."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Small", as: .systemSmall) {
    StandTimerWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot()
        s.pomodoroCompleted = 3
        s.pomodoroTarget = 8
        s.pomodoroPhase = "work"
        return s
    }(), cardID: "standTimer")
}

#Preview("Medium", as: .systemMedium) {
    StandTimerWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot()
        s.pomodoroCompleted = 5
        s.pomodoroTarget = 8
        s.pomodoroPhase = "standAlert"
        return s
    }(), cardID: "standTimer")
}
#endif
