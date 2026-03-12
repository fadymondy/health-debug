// EnergyWidget.swift
// HealthDebugWidgets — home screen widget for active energy burned.

import SwiftUI
import WidgetKit

// MARK: - Views

private struct EnergySmallView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color(.systemOrange))

            Text(String(Int(snapshot.activeEnergy)))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(LocalizedStringKey("kcal"))
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(LocalizedStringKey("Energy"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }
}

private struct EnergyMediumView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double {
        guard snapshot.energyGoal > 0 else { return 0 }
        return min(snapshot.activeEnergy / snapshot.energyGoal, 1.0)
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label(LocalizedStringKey("Energy"), systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(Color(.systemOrange))

                Text(String(Int(snapshot.activeEnergy)))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text(LocalizedStringKey("kcal"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemOrange).opacity(0.2))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemOrange))
                            .frame(width: geo.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)

                Text(goalText())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            // Circular percentage badge
            ZStack {
                Circle()
                    .stroke(Color(.systemOrange).opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(.systemOrange), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(.systemOrange))
            }
            .frame(width: 64, height: 64)
        }
        .padding(16)
    }

    private func goalText() -> String {
        let goal = Int(snapshot.energyGoal)
        return "\(NSLocalizedString("of goal", comment: "")) \(goal) \(NSLocalizedString("kcal", comment: ""))"
    }
}

// MARK: - Entry View

struct EnergyWidgetEntryView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                EnergySmallView(snapshot: entry.snapshot)
            case .systemMedium:
                EnergyMediumView(snapshot: entry.snapshot)
            default:
                EnergySmallView(snapshot: entry.snapshot)
            }
        }
        .containerBackground(for: .widget) { Color(.systemBackground) }
        .widgetURL(URL(string: "healthdebug://energy")!)
    }
}

// MARK: - Widget

struct EnergyWidget: Widget {
    static let kind = "EnergyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HealthTimelineProvider(cardID: "energy")) { entry in
            EnergyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Energy"))
        .description(LocalizedStringKey("Monitor your active energy burn and daily goal."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Small", as: .systemSmall) {
    EnergyWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.activeEnergy = 312; s.energyGoal = 500; return s
    }(), cardID: "energy")
}

#Preview("Medium", as: .systemMedium) {
    EnergyWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.activeEnergy = 312; s.energyGoal = 500; return s
    }(), cardID: "energy")
}
#endif
