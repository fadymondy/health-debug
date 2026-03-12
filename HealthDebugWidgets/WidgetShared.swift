// WidgetShared.swift
// Standalone copy of WidgetSnapshot/WidgetDataStore for the widget extension process.
// The widget extension cannot link HealthDebugKit (which requires HealthKit),
// so we replicate the minimal data types here. Both must stay in sync.

import Foundation
import SwiftUI

// MARK: - IBM Plex Sans helper (widget process — mirrors Theme.swift in main app)

extension Font {
    static var ibmWidgetFamily: String {
        let isArabic = Bundle.main.preferredLocalizations.first?.hasPrefix("ar") == true
        return isArabic ? "IBM Plex Sans Arabic" : "IBMPlexSans"
    }

    static func ibmWidget(_ style: Font.TextStyle) -> Font {
        .custom(ibmWidgetFamily, size: widgetSize(for: style), relativeTo: style)
    }

    private static func widgetSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .title:       return 28
        case .title2:      return 22
        case .title3:      return 20
        case .headline:    return 17
        case .body:        return 17
        case .subheadline: return 15
        case .footnote:    return 13
        case .caption:     return 12
        case .caption2:    return 11
        @unknown default:  return 15
        }
    }
}

extension View {
    /// Applies IBM Plex Sans as the default font for all Text in widget views.
    func ibmFont() -> some View {
        self.font(.custom(Font.ibmWidgetFamily, size: 15, relativeTo: .body))
    }
}

struct WidgetSnapshot: Codable {
    var steps: Double = 0
    var stepsGoal: Double = 10000
    var activeEnergy: Double = 0
    var energyGoal: Double = 500
    var heartRate: Double = 0
    var sleepHours: Double = 0
    var sleepGoal: Double = 8
    var hydrationMl: Int = 0
    var hydrationGoalMl: Int = 2500
    var pomodoroCompleted: Int = 0
    var pomodoroTarget: Int = 8
    var pomodoroPhase: String = "idle"
    var nutritionSafetyScore: Int = 0
    var mealsLogged: Int = 0
    var caffeineIsClean: Bool = true
    var caffeineDrinksToday: Int = 0
    var shutdownActive: Bool = false
    var shutdownSecondsRemaining: TimeInterval = 0
    var weightKg: Double = 0
    var weightBodyFat: Double = 0
    var dailyFlowScore: Int = 0
    var dailyFlowTotal: Int = 6
    var updatedAt: Date = .now
}

final class WidgetDataStore: @unchecked Sendable {
    nonisolated(unsafe) static let shared = WidgetDataStore()
    private static let appGroupID = "group.io.3x1.HealthDebug"
    private static let snapshotKey = "widget_snapshot_v1"
    private let defaults: UserDefaults

    private init() {
        defaults = UserDefaults(suiteName: Self.appGroupID) ?? UserDefaults.standard
    }

    func read() -> WidgetSnapshot {
        guard
            let data = defaults.data(forKey: Self.snapshotKey),
            let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return WidgetSnapshot() }
        return snapshot
    }
}
