import Foundation
import SwiftData

// MARK: - WaterLog Queries

public extension WaterLog {
    /// Fetch descriptor for today's water logs, sorted by time.
    static func todayDescriptor() -> FetchDescriptor<WaterLog> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        var descriptor = FetchDescriptor<WaterLog>(
            predicate: #Predicate { log in
                log.timestamp >= startOfDay && log.timestamp < endOfDay
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 100
        return descriptor
    }

    /// Total milliliters consumed today.
    static func todayTotal(in context: ModelContext) -> Int {
        let logs = (try? context.fetch(todayDescriptor())) ?? []
        return logs.reduce(0) { $0 + $1.amount }
    }
}

// MARK: - MealLog Queries

public extension MealLog {
    /// Fetch descriptor for today's meals, sorted by time.
    static func todayDescriptor() -> FetchDescriptor<MealLog> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return FetchDescriptor<MealLog>(
            predicate: #Predicate { log in
                log.timestamp >= startOfDay && log.timestamp < endOfDay
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
    }

    /// Fetch only unsafe meals logged today.
    static func todayUnsafeDescriptor() -> FetchDescriptor<MealLog> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return FetchDescriptor<MealLog>(
            predicate: #Predicate { log in
                log.timestamp >= startOfDay && log.timestamp < endOfDay && !log.isSafe
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
    }
}

// MARK: - CaffeineLog Queries

public extension CaffeineLog {
    /// Fetch today's caffeine logs.
    static func todayDescriptor() -> FetchDescriptor<CaffeineLog> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return FetchDescriptor<CaffeineLog>(
            predicate: #Predicate { log in
                log.timestamp >= startOfDay && log.timestamp < endOfDay
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
    }

    /// Count of sugar-based caffeine today.
    static func todaySugarCount(in context: ModelContext) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<CaffeineLog>(
            predicate: #Predicate { log in
                log.timestamp >= startOfDay && log.timestamp < endOfDay && log.isSugarBased
            }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }
}

// MARK: - PomodoroSession Queries are defined in PomodoroSession.swift

// MARK: - UserProfile Query

public extension UserProfile {
    /// Fetch the single user profile.
    static func currentDescriptor() -> FetchDescriptor<UserProfile> {
        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1
        return descriptor
    }
}

// MARK: - SleepConfig Query

public extension SleepConfig {
    /// Fetch the current sleep configuration.
    static func currentDescriptor() -> FetchDescriptor<SleepConfig> {
        var descriptor = FetchDescriptor<SleepConfig>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return descriptor
    }
}
