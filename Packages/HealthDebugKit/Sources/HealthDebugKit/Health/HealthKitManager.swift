import Foundation
import HealthKit

/// Bundles Zepp smart scale metrics synced via Apple Health.
public struct ZeppMetrics: Sendable {
    public var weight: Double // kg (baseline: 108)
    public var bodyFatPercent: Double // (Zepp body fat)
    public var lastUpdated: Date?

    public init(weight: Double = 0, bodyFatPercent: Double = 0, lastUpdated: Date? = nil) {
        self.weight = weight
        self.bodyFatPercent = bodyFatPercent
        self.lastUpdated = lastUpdated
    }
}

/// Manages all HealthKit interactions: authorization, reading, and writing health data.
/// Used on iOS and watchOS (not available on macOS).
@MainActor
public final class HealthKitManager: ObservableObject {

    public static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    // MARK: - Published State

    @Published public var isAuthorized = false
    @Published public var stepCount: Double = 0
    @Published public var activeEnergy: Double = 0 // kcal
    @Published public var heartRate: Double = 0 // bpm
    @Published public var sleepHours: Double = 0 // last night
    @Published public var zeppMetrics = ZeppMetrics()

    // MARK: - Types to Read

    private static let readTypes: Set<HKObjectType> = {
        var types: Set<HKObjectType> = []
        let quantityIds: [HKQuantityTypeIdentifier] = [
            .stepCount, .activeEnergyBurned, .heartRate,
            .bodyMass, .bodyFatPercentage,
        ]
        for id in quantityIds {
            if let t = HKQuantityType.quantityType(forIdentifier: id) {
                types.insert(t)
            }
        }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }()

    // MARK: - Authorization

    public var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    public func requestAuthorization() async throws {
        guard isAvailable else { return }
        try await healthStore.requestAuthorization(toShare: [], read: Self.readTypes)
        isAuthorized = true
    }

    // MARK: - Fetch Today's Steps

    public func fetchTodaySteps() async throws {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let predicate = todayPredicate()

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: stepType, predicate: predicate),
            options: .cumulativeSum
        )
        let result = try await descriptor.result(for: healthStore)
        stepCount = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
    }

    // MARK: - Fetch Today's Active Energy

    public func fetchTodayActiveEnergy() async throws {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let predicate = todayPredicate()

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: energyType, predicate: predicate),
            options: .cumulativeSum
        )
        let result = try await descriptor.result(for: healthStore)
        activeEnergy = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
    }

    // MARK: - Fetch Latest Heart Rate

    public func fetchLatestHeartRate() async throws {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let descriptor = HKSampleQueryDescriptor<HKQuantitySample>(
            predicates: [.quantitySample(type: hrType)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        let results = try await descriptor.result(for: healthStore)
        if let sample = results.first {
            heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        }
    }

    // MARK: - Fetch Last Night's Sleep

    public func fetchLastNightSleep() async throws {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let calendar = Calendar.current
        let now = Date.now
        let yesterday6pm = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -1, to: now)!)!
        let today12pm = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now)!

        let predicate = HKQuery.predicateForSamples(withStart: yesterday6pm, end: today12pm, options: .strictStartDate)

        let descriptor = HKSampleQueryDescriptor<HKCategorySample>(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        let results = try await descriptor.result(for: healthStore)

        // Sum only asleep categories (not inBed)
        var totalSeconds: TimeInterval = 0
        for sample in results {
            let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)
            switch value {
            case .asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified:
                totalSeconds += sample.endDate.timeIntervalSince(sample.startDate)
            default:
                break
            }
        }
        sleepHours = totalSeconds / 3600.0
    }

    // MARK: - Fetch Zepp Scale Metrics (via Apple Health)

    public func fetchZeppMetrics() async throws {
        // Weight
        if let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            let descriptor = HKSampleQueryDescriptor<HKQuantitySample>(
                predicates: [.quantitySample(type: weightType)],
                sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
                limit: 1
            )
            let results = try await descriptor.result(for: healthStore)
            if let sample = results.first {
                zeppMetrics.weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                zeppMetrics.lastUpdated = sample.endDate
            }
        }

        // Body Fat
        if let bfType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) {
            let descriptor = HKSampleQueryDescriptor<HKQuantitySample>(
                predicates: [.quantitySample(type: bfType)],
                sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
                limit: 1
            )
            let results = try await descriptor.result(for: healthStore)
            if let sample = results.first {
                zeppMetrics.bodyFatPercent = sample.quantity.doubleValue(for: .percent()) * 100
            }
        }
    }

    // MARK: - Refresh All

    public func refreshAll() async {
        do {
            try await fetchTodaySteps()
            try await fetchTodayActiveEnergy()
            try await fetchLatestHeartRate()
            try await fetchLastNightSleep()
            try await fetchZeppMetrics()
        } catch {
            print("[HealthDebug] HealthKit refresh error: \(error)")
        }
    }

    // MARK: - Helpers

    private func todayPredicate() -> NSPredicate {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        return HKQuery.predicateForSamples(withStart: startOfDay, end: .now, options: .strictStartDate)
    }
}
