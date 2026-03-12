// WidgetActions.swift
// AppIntent definitions for interactive widget buttons.
// Intents run in the widget extension process.
// They update the shared WidgetSnapshot immediately for live feedback,
// AND queue a pending command for the main app to persist via SwiftData.

import AppIntents
import WidgetKit
import Foundation

// MARK: - Shared action queue (widget writes, main app consumes)

enum WidgetActionStore {
    private static let appGroupID = "group.io.3x1.HealthDebug"
    nonisolated(unsafe) static let defaults: UserDefaults =
        UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard

    // Keys must match WidgetActionReader in HealthDebugKit
    static let hydrationPendingKey = "widget_action_hydration_ml"
    static let pomodoroActionKey   = "widget_action_pomodoro"
    static let caffeineLogKey      = "widget_action_caffeine_clean"
    static let snapshotKey         = "widget_snapshot_v1"

    static func queueHydration(ml: Int) {
        // Queue for main app persistence
        let existing = defaults.integer(forKey: hydrationPendingKey)
        defaults.set(existing + ml, forKey: hydrationPendingKey)

        // Immediately update snapshot so widget re-renders with new value
        updateSnapshot { snapshot in
            snapshot.hydrationMl += ml
        }
    }

    static func queuePomodoro(action: String) {
        defaults.set(action, forKey: pomodoroActionKey)

        // Update phase in snapshot for immediate visual feedback
        updateSnapshot { snapshot in
            if action == "start" {
                snapshot.pomodoroPhase = "work"
            } else if action == "break" {
                snapshot.pomodoroPhase = "shortBreak"
            }
        }
    }

    static func queueCaffeineClean() {
        defaults.set(true, forKey: caffeineLogKey)

        // Immediately increment drink count in snapshot
        updateSnapshot { snapshot in
            snapshot.caffeineDrinksToday += 1
        }
    }

    private static func updateSnapshot(_ mutate: (inout WidgetSnapshot) -> Void) {
        var snapshot: WidgetSnapshot
        if let data = defaults.data(forKey: snapshotKey),
           let decoded = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) {
            snapshot = decoded
        } else {
            snapshot = WidgetSnapshot()
        }
        mutate(&snapshot)
        snapshot.updatedAt = .now
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: snapshotKey)
        }
    }
}

// MARK: - Hydration intents

struct LogHydration250Intent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Log 250ml Water"
    nonisolated(unsafe) static var description = IntentDescription("Log 250ml of water intake")
    nonisolated(unsafe) static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        WidgetActionStore.queueHydration(ml: 250)
        WidgetCenter.shared.reloadTimelines(ofKind: "HydrationWidget")
        return .result()
    }
}

struct LogHydration500Intent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Log 500ml Water"
    nonisolated(unsafe) static var description = IntentDescription("Log 500ml of water intake")
    nonisolated(unsafe) static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        WidgetActionStore.queueHydration(ml: 500)
        WidgetCenter.shared.reloadTimelines(ofKind: "HydrationWidget")
        return .result()
    }
}

// MARK: - Pomodoro intents

struct StartFocusIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Start Focus Session"
    nonisolated(unsafe) static var description = IntentDescription("Start a Pomodoro focus session")
    nonisolated(unsafe) static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        WidgetActionStore.queuePomodoro(action: "start")
        WidgetCenter.shared.reloadTimelines(ofKind: "StandTimerWidget")
        return .result()
    }
}

struct TakeBreakIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Take a Break"
    nonisolated(unsafe) static var description = IntentDescription("Start a short break from focus")
    nonisolated(unsafe) static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        WidgetActionStore.queuePomodoro(action: "break")
        WidgetCenter.shared.reloadTimelines(ofKind: "StandTimerWidget")
        return .result()
    }
}

// MARK: - Caffeine intent

struct LogCleanDrinkIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Log Clean Drink"
    nonisolated(unsafe) static var description = IntentDescription("Log a clean caffeine drink")
    nonisolated(unsafe) static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        WidgetActionStore.queueCaffeineClean()
        WidgetCenter.shared.reloadTimelines(ofKind: "CaffeineWidget")
        return .result()
    }
}
