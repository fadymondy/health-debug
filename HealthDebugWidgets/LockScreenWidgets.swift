// LockScreenWidgets.swift
// HealthDebugWidgets — Six lock screen widgets (accessoryCircular + accessoryRectangular).
// Families: accessoryCircular, accessoryRectangular (iOS 16+ lock screen).
// Minimum deployment: iOS 17.0. Swift 5.9+.

import Foundation
import SwiftUI
import WidgetKit

// MARK: - Helpers

private func stepsAbbreviated(_ value: Double) -> String {
    if value >= 1000 {
        return String(format: "%.1fk", value / 1000)
    }
    return String(Int(value))
}

private func clampedProgress(_ value: Double, over total: Double) -> Double {
    guard total > 0 else { return 0 }
    return min(value / total, 1.0)
}

// MARK: - Heart Rate Zone (lock screen)

private enum LockHeartZone {
    case low, normal, elevated, high

    init(bpm: Double) {
        switch bpm {
        case ..<60:       self = .low
        case 60..<100:    self = .normal
        case 100..<120:   self = .elevated
        default:          self = .high
        }
    }

    var label: LocalizedStringKey {
        switch self {
        case .low:       return "Low"
        case .normal:    return "Normal"
        case .elevated:  return "Elevated"
        case .high:      return "High"
        }
    }

    // Normalized 0–1 value suitable for a Gauge (maps BPM range 30–200 onto 0…1).
    var gaugeValue: Double {
        // We pass actual BPM via gaugeFrom/through, but keep this around for
        // contexts where a plain fraction is cleaner.
        0.5
    }
}

// MARK: - Sleep Quality Label

private func sleepQualityLabel(hours: Double, goal: Double) -> LocalizedStringKey {
    let ratio = goal > 0 ? hours / goal : 0
    switch ratio {
    case 1.0...:  return "Great"
    case 0.75...: return "Good"
    case 0.5...:  return "Fair"
    default:      return "Short"
    }
}

// MARK: - Daily Flow Tint

private func flowColor(score: Int) -> Color {
    if score >= 5 { return .green }
    if score >= 3 { return .orange }
    return .red
}

// MARK: - STEPS LOCK WIDGET ───────────────────────────────────────────────────

// MARK: Views

private struct StepsLockCircularView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double { clampedProgress(snapshot.steps, over: snapshot.stepsGoal) }

    var body: some View {
        Gauge(
            value: progress,
            in: 0...1
        ) {
            Image(systemName: "figure.walk")
                .widgetAccentable()
        } currentValueLabel: {
            Text(stepsAbbreviated(snapshot.steps))
                .font(.system(.caption2, design: .rounded).bold())
                .widgetAccentable()
        } minimumValueLabel: {
            Text("0")
                .font(.caption2)
        } maximumValueLabel: {
            Text("10k")
                .font(.caption2)
        }
        .gaugeStyle(.accessoryCircular)
    }
}

private struct StepsLockRectangularView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.walk")
                .font(.body)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey("Steps"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(stepsAbbreviated(snapshot.steps))
                    .font(.system(.title3, design: .rounded).bold())
                    .widgetAccentable()
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: Entry View

struct StepsLockWidgetView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                StepsLockCircularView(snapshot: entry.snapshot)
            case .accessoryRectangular:
                StepsLockRectangularView(snapshot: entry.snapshot)
            default:
                StepsLockCircularView(snapshot: entry.snapshot)
            }
        }
        .ibmFont()
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "healthdebug://steps")!)
    }
}

// MARK: Widget

struct StepsLockWidget: Widget {
    let kind: String = "StepsLock"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthTimelineProvider(cardID: "steps")) { entry in
            StepsLockWidgetView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Steps"))
        .description(LocalizedStringKey("Track your daily steps on the lock screen."))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - HEART RATE LOCK WIDGET ──────────────────────────────────────────────

// MARK: Views

private struct HeartRateLockCircularView: View {
    let snapshot: WidgetSnapshot

    // Normalize BPM into 0…1 over a 30–200 bpm range for the gauge.
    private var gaugeValue: Double {
        let bpm = snapshot.heartRate
        return min(max((bpm - 30) / (200 - 30), 0), 1)
    }

    var body: some View {
        Gauge(
            value: gaugeValue,
            in: 0...1
        ) {
            Image(systemName: "heart.fill")
                .widgetAccentable()
        } currentValueLabel: {
            Text("\(Int(snapshot.heartRate))")
                .font(.system(.caption2, design: .rounded).bold())
                .widgetAccentable()
        }
        .gaugeStyle(.accessoryCircular)
    }
}

private struct HeartRateLockRectangularView: View {
    let snapshot: WidgetSnapshot

    private var zone: LockHeartZone { LockHeartZone(bpm: snapshot.heartRate) }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "heart.fill")
                .font(.body)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey("Heart Rate"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(snapshot.heartRate))")
                        .font(.system(.title3, design: .rounded).bold())
                        .widgetAccentable()
                    Text(LocalizedStringKey("bpm"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(zone.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: Entry View

struct HeartRateLockWidgetView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                HeartRateLockCircularView(snapshot: entry.snapshot)
            case .accessoryRectangular:
                HeartRateLockRectangularView(snapshot: entry.snapshot)
            default:
                HeartRateLockCircularView(snapshot: entry.snapshot)
            }
        }
        .ibmFont()
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "healthdebug://heartRate")!)
    }
}

// MARK: Widget

struct HeartRateLockWidget: Widget {
    let kind: String = "HeartRateLock"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthTimelineProvider(cardID: "heartRate")) { entry in
            HeartRateLockWidgetView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Heart Rate"))
        .description(LocalizedStringKey("View your current heart rate on the lock screen."))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - HYDRATION LOCK WIDGET ───────────────────────────────────────────────

// MARK: Views

private struct HydrationLockCircularView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double {
        clampedProgress(Double(snapshot.hydrationMl), over: Double(snapshot.hydrationGoalMl))
    }

    var body: some View {
        Gauge(
            value: progress,
            in: 0...1
        ) {
            Image(systemName: "drop.fill")
                .widgetAccentable()
        } currentValueLabel: {
            Text("\(snapshot.hydrationMl)")
                .font(.system(.caption2, design: .rounded).bold())
                .widgetAccentable()
        } minimumValueLabel: {
            Text("0")
                .font(.caption2)
        } maximumValueLabel: {
            Text(LocalizedStringKey("ml"))
                .font(.caption2)
        }
        .gaugeStyle(.accessoryCircular)
    }
}

private struct HydrationLockRectangularView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "drop.fill")
                .font(.body)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey("Hydration"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(snapshot.hydrationMl) / \(snapshot.hydrationGoalMl) ml")
                    .font(.system(.title3, design: .rounded).bold())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .widgetAccentable()
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: Entry View

struct HydrationLockWidgetView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                HydrationLockCircularView(snapshot: entry.snapshot)
            case .accessoryRectangular:
                HydrationLockRectangularView(snapshot: entry.snapshot)
            default:
                HydrationLockCircularView(snapshot: entry.snapshot)
            }
        }
        .ibmFont()
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "healthdebug://hydration")!)
    }
}

// MARK: Widget

struct HydrationLockWidget: Widget {
    let kind: String = "HydrationLock"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthTimelineProvider(cardID: "hydration")) { entry in
            HydrationLockWidgetView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Hydration"))
        .description(LocalizedStringKey("Track your daily hydration on the lock screen."))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - STAND TIMER LOCK WIDGET ─────────────────────────────────────────────

// MARK: Views

private struct StandTimerLockCircularView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double {
        clampedProgress(Double(snapshot.pomodoroCompleted), over: Double(snapshot.pomodoroTarget))
    }

    var body: some View {
        Gauge(
            value: progress,
            in: 0...1
        ) {
            Image(systemName: "timer")
                .widgetAccentable()
        } currentValueLabel: {
            Text("\(snapshot.pomodoroCompleted)")
                .font(.system(.caption2, design: .rounded).bold())
                .widgetAccentable()
        }
        .gaugeStyle(.accessoryCircular)
    }
}

private struct StandTimerLockRectangularView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.body)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey("Stand Timer"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(snapshot.pomodoroCompleted)/\(snapshot.pomodoroTarget) \(NSLocalizedString("sessions", comment: ""))")
                    .font(.system(.title3, design: .rounded).bold())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .widgetAccentable()
                Text(LocalizedStringKey(snapshot.pomodoroPhase))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: Entry View

struct StandTimerLockWidgetView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                StandTimerLockCircularView(snapshot: entry.snapshot)
            case .accessoryRectangular:
                StandTimerLockRectangularView(snapshot: entry.snapshot)
            default:
                StandTimerLockCircularView(snapshot: entry.snapshot)
            }
        }
        .ibmFont()
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "healthdebug://standTimer")!)
    }
}

// MARK: Widget

struct StandTimerLockWidget: Widget {
    let kind: String = "StandTimerLock"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthTimelineProvider(cardID: "standTimer")) { entry in
            StandTimerLockWidgetView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Stand Timer"))
        .description(LocalizedStringKey("Track your standing sessions on the lock screen."))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - SLEEP LOCK WIDGET ───────────────────────────────────────────────────

// MARK: Views

private struct SleepLockCircularView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double { clampedProgress(snapshot.sleepHours, over: snapshot.sleepGoal) }

    var body: some View {
        Gauge(
            value: progress,
            in: 0...1
        ) {
            Image(systemName: "moon.stars.fill")
                .widgetAccentable()
        } currentValueLabel: {
            Text(String(format: "%.1f", snapshot.sleepHours))
                .font(.system(.caption2, design: .rounded).bold())
                .widgetAccentable()
        }
        .gaugeStyle(.accessoryCircular)
    }
}

private struct SleepLockRectangularView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "moon.stars.fill")
                .font(.body)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey("Sleep"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(String(format: NSLocalizedString("%.1f hrs", comment: ""), snapshot.sleepHours))
                    .font(.system(.title3, design: .rounded).bold())
                    .widgetAccentable()
                Text(sleepQualityLabel(hours: snapshot.sleepHours, goal: snapshot.sleepGoal))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: Entry View

struct SleepLockWidgetView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                SleepLockCircularView(snapshot: entry.snapshot)
            case .accessoryRectangular:
                SleepLockRectangularView(snapshot: entry.snapshot)
            default:
                SleepLockCircularView(snapshot: entry.snapshot)
            }
        }
        .ibmFont()
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "healthdebug://sleep")!)
    }
}

// MARK: Widget

struct SleepLockWidget: Widget {
    let kind: String = "SleepLock"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthTimelineProvider(cardID: "sleep")) { entry in
            SleepLockWidgetView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Sleep"))
        .description(LocalizedStringKey("View your sleep hours on the lock screen."))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - DAILY FLOW LOCK WIDGET ──────────────────────────────────────────────

// MARK: Views

private struct DailyFlowLockCircularView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double { clampedProgress(Double(snapshot.dailyFlowScore), over: 6.0) }
    private var tint: Color { flowColor(score: snapshot.dailyFlowScore) }

    var body: some View {
        Gauge(
            value: progress,
            in: 0...1
        ) {
            Image(systemName: "checklist")
                .widgetAccentable()
        } currentValueLabel: {
            Text("\(snapshot.dailyFlowScore)/6")
                .font(.system(.caption2, design: .rounded).bold())
                .foregroundStyle(tint)
                .widgetAccentable()
        }
        .gaugeStyle(.accessoryCircular)
        .tint(tint)
    }
}

private struct DailyFlowLockRectangularView: View {
    let snapshot: WidgetSnapshot

    private var tint: Color { flowColor(score: snapshot.dailyFlowScore) }
    private var percentage: Int { Int((Double(snapshot.dailyFlowScore) / 6.0) * 100) }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checklist")
                .font(.body)
                .foregroundStyle(tint)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey("Daily Flow"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(snapshot.dailyFlowScore) \(NSLocalizedString("of 6 goals", comment: ""))")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(tint)
                    .widgetAccentable()
                Text("\(percentage)%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: Entry View

struct DailyFlowLockWidgetView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                DailyFlowLockCircularView(snapshot: entry.snapshot)
            case .accessoryRectangular:
                DailyFlowLockRectangularView(snapshot: entry.snapshot)
            default:
                DailyFlowLockCircularView(snapshot: entry.snapshot)
            }
        }
        .ibmFont()
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "healthdebug://dailyFlow")!)
    }
}

// MARK: Widget

struct DailyFlowLockWidget: Widget {
    let kind: String = "DailyFlowLock"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthTimelineProvider(cardID: "dailyFlow")) { entry in
            DailyFlowLockWidgetView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Daily Flow"))
        .description(LocalizedStringKey("See your daily goal progress on the lock screen."))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Previews ─────────────────────────────────────────────────────────────

#if DEBUG

private var previewSnapshot: WidgetSnapshot {
    var s = WidgetSnapshot()
    s.steps = 8247
    s.stepsGoal = 10000
    s.heartRate = 72
    s.hydrationMl = 1200
    s.hydrationGoalMl = 2500
    s.pomodoroCompleted = 5
    s.pomodoroTarget = 8
    s.pomodoroPhase = "work"
    s.sleepHours = 6.5
    s.sleepGoal = 8
    s.dailyFlowScore = 4
    return s
}

// Steps
#Preview("Steps Circular", as: .accessoryCircular) {
    StepsLockWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: previewSnapshot, cardID: "steps")
}

#Preview("Steps Rectangular", as: .accessoryRectangular) {
    StepsLockWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: previewSnapshot, cardID: "steps")
}

// Heart Rate
#Preview("Heart Rate Circular", as: .accessoryCircular) {
    HeartRateLockWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: previewSnapshot, cardID: "heartRate")
}

#Preview("Heart Rate Rectangular", as: .accessoryRectangular) {
    HeartRateLockWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: previewSnapshot, cardID: "heartRate")
}

// Hydration
#Preview("Hydration Circular", as: .accessoryCircular) {
    HydrationLockWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: previewSnapshot, cardID: "hydration")
}

#Preview("Hydration Rectangular", as: .accessoryRectangular) {
    HydrationLockWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: previewSnapshot, cardID: "hydration")
}

// Stand Timer
#Preview("Stand Timer Circular", as: .accessoryCircular) {
    StandTimerLockWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: previewSnapshot, cardID: "standTimer")
}

#Preview("Stand Timer Rectangular", as: .accessoryRectangular) {
    StandTimerLockWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: previewSnapshot, cardID: "standTimer")
}

// Sleep
#Preview("Sleep Circular", as: .accessoryCircular) {
    SleepLockWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: previewSnapshot, cardID: "sleep")
}

#Preview("Sleep Rectangular", as: .accessoryRectangular) {
    SleepLockWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: previewSnapshot, cardID: "sleep")
}

// Daily Flow
#Preview("Daily Flow Circular", as: .accessoryCircular) {
    DailyFlowLockWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: previewSnapshot, cardID: "dailyFlow")
}

#Preview("Daily Flow Rectangular", as: .accessoryRectangular) {
    DailyFlowLockWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: previewSnapshot, cardID: "dailyFlow")
}

#endif
