// NutritionWidget.swift
// HealthDebugWidgets — home screen widget for nutrition safety score.

import SwiftUI
import WidgetKit

// MARK: - Safety Level

private enum NutritionSafetyLevel {
    case safe, caution, unsafe

    init(score: Int) {
        if score >= 80 { self = .safe }
        else if score >= 60 { self = .caution }
        else { self = .unsafe }
    }

    var label: LocalizedStringKey {
        switch self {
        case .safe:    return "Safe"
        case .caution: return "Caution"
        case .unsafe:  return "Unsafe"
        }
    }

    var color: Color {
        switch self {
        case .safe:    return Color(.systemGreen)
        case .caution: return Color(.systemOrange)
        case .unsafe:  return Color(.systemRed)
        }
    }
}

// MARK: - Views

private struct NutritionSmallView: View {
    let snapshot: WidgetSnapshot

    private var level: NutritionSafetyLevel { NutritionSafetyLevel(score: snapshot.nutritionSafetyScore) }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "fork.knife")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(level.color)

            Text("\(snapshot.nutritionSafetyScore)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(level.label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(level.color)

            Text(mealsText())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    private func mealsText() -> String {
        "\(snapshot.mealsLogged) \(NSLocalizedString("meals", comment: ""))"
    }
}

private struct NutritionMediumView: View {
    let snapshot: WidgetSnapshot

    private var level: NutritionSafetyLevel { NutritionSafetyLevel(score: snapshot.nutritionSafetyScore) }
    private var progress: Double { Double(snapshot.nutritionSafetyScore) / 100.0 }

    var body: some View {
        HStack(spacing: 16) {
            // Score ring
            ZStack {
                Circle()
                    .stroke(level.color.opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(level.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 1) {
                    Text("\(snapshot.nutritionSafetyScore)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("/100")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 4) {
                Label(LocalizedStringKey("Nutrition"), systemImage: "fork.knife")
                    .font(.caption)
                    .foregroundStyle(Color(.systemGreen))

                Text(level.label)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(level.color)

                Text(mealsText())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(scoreSubtitle())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private func mealsText() -> String {
        "\(snapshot.mealsLogged) \(NSLocalizedString("meals", comment: "")) \(NSLocalizedString("today", comment: ""))"
    }

    private func scoreSubtitle() -> String {
        "\(NSLocalizedString("Safety score", comment: "")): \(snapshot.nutritionSafetyScore)/100"
    }
}

// MARK: - Entry View

struct NutritionWidgetEntryView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                NutritionSmallView(snapshot: entry.snapshot)
            case .systemMedium:
                NutritionMediumView(snapshot: entry.snapshot)
            default:
                NutritionSmallView(snapshot: entry.snapshot)
            }
        }
        .containerBackground(for: .widget) { Color(.systemBackground) }
        .widgetURL(URL(string: "healthdebug://nutrition")!)
    }
}

// MARK: - Widget

struct NutritionWidget: Widget {
    static let kind = "NutritionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HealthTimelineProvider(cardID: "nutrition")) { entry in
            NutritionWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("Nutrition"))
        .description(LocalizedStringKey("Monitor your nutrition safety score and daily meals."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Small", as: .systemSmall) {
    NutritionWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.nutritionSafetyScore = 85; s.mealsLogged = 3; return s
    }(), cardID: "nutrition")
}

#Preview("Medium", as: .systemMedium) {
    NutritionWidget()
} timeline: {
    HealthWidgetEntry(date: .now, snapshot: {
        var s = WidgetSnapshot(); s.nutritionSafetyScore = 65; s.mealsLogged = 2; return s
    }(), cardID: "nutrition")
}
#endif
