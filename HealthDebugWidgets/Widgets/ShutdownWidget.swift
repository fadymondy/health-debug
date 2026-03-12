// ShutdownWidget.swift
// HealthDebugWidgets — home screen widget for the GERD system shutdown timer.

import SwiftUI
import WidgetKit

// MARK: - Helpers

private func formatCountdown(_ seconds: TimeInterval) -> String {
    guard seconds > 0 else { return "00:00" }
    let h = Int(seconds) / 3600
    let m = (Int(seconds) % 3600) / 60
    return String(format: "%02d:%02d", h, m)
}

// MARK: - Views

private struct ShutdownSmallView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color(.systemRed))

            Text(snapshot.shutdownActive
                 ? LocalizedStringKey("Active")
                 : LocalizedStringKey("Inactive"))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(snapshot.shutdownActive ? Color(.systemRed) : .secondary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            if snapshot.shutdownActive && snapshot.shutdownSecondsRemaining > 0 {
                Text(formatCountdown(snapshot.shutdownSecondsRemaining))
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(.systemRed))
            }
        }
        .padding(12)
    }
}

private struct ShutdownMediumView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: 16) {
            // Status icon
            ZStack {
                Circle()
                    .fill(snapshot.shutdownActive
                          ? Color(.systemRed).opacity(0.15)
                          : Color(.systemGray).opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(snapshot.shutdownActive ? Color(.systemRed) : Color(.systemGray))
            }

            VStack(alignment: .leading, spacing: 4) {
                Label(LocalizedStringKey("Shutdown"), systemImage: "moon.zzz.fill")
                    .font(.caption)
                    .foregroundStyle(Color(.systemRed))

                Text(snapshot.shutdownActive
                     ? LocalizedStringKey("Active")
                     : LocalizedStringKey("Inactive"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(snapshot.shutdownActive ? Color(.systemRed) : .secondary)

                if snapshot.shutdownActive && snapshot.shutdownSecondsRemaining > 0 {
                    Text(formatCountdown(snapshot.shutdownSecondsRemaining))
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(.systemRed))
                }

                Text(LocalizedStringKey("GERD Shutdown"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }
}

// MARK: - Entry View

struct ShutdownWidgetEntryView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                ShutdownSmallView(snapshot: entry.snapshot)
            case .systemMedium:
                ShutdownMediumView(snapshot: entry.snapshot)
            default:
                ShutdownSmallView(snapshot: entry.snapshot)
            }
        }
        .containerBackground(for: .widget) { Color(.systemBackground) }
        .widgetURL(URL(string: "healthdebug://shutdown")!)
    }
}

// MARK: - Widget

struct ShutdownWidget: Widget {
    static let kind = "ShutdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HealthTimelineProvider(cardID: "shutdown")) { entry in
            ShutdownWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Shutdown"))
        .description(LocalizedStringKey("Check your GERD shutdown timer status and countdown."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Small Active", as: .systemSmall) {
    ShutdownWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot()
        s.shutdownActive = true
        s.shutdownSecondsRemaining = 7200
        return s
    }(), cardID: "shutdown")
}

#Preview("Medium Inactive", as: .systemMedium) {
    ShutdownWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.shutdownActive = false; return s
    }(), cardID: "shutdown")
}
#endif
