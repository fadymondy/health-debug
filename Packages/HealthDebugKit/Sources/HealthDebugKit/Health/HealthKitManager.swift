import Foundation
import HealthKit

/// Manages all HealthKit interactions: authorization, reading, and writing health data.
/// Used on iOS and watchOS (not available on macOS).
@MainActor
public final class HealthKitManager: ObservableObject {

    public static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    @Published public var isAuthorized = false
    @Published public var stepCount: Double = 0
    @Published public var activeEnergy: Double = 0
    @Published public var heartRate: Double = 0
    @Published public var latestWeight: Double = 0 // kg
    @Published public var latestVisceralFat: Int = 0
    @Published public var latestBodyWater: Double = 0 // percent
    @Published public var latestBodyFat: Double = 0 // percent

    // MARK: - Types to Read

    private static let readTypes: Set<HKObjectType> = {
        var types: Set<HKObjectType> = []
        if let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepCount)
        }
        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }
        if let bodyFat = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) {
            types.insert(bodyFat)
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

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: .now, options: .strictStartDate)

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

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: .now, options: .strictStartDate)

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

        var descriptor = HKSampleQueryDescriptor<HKQuantitySample>(
            predicates: [.quantitySample(type: hrType)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )

        let results = try await descriptor.result(for: healthStore)
        if let sample = results.first {
            heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        }
    }

    // MARK: - Fetch Latest Weight (Zepp Scale via Apple Health)

    public func fetchLatestWeight() async throws {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }

        var descriptor = HKSampleQueryDescriptor<HKQuantitySample>(
            predicates: [.quantitySample(type: weightType)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )

        let results = try await descriptor.result(for: healthStore)
        if let sample = results.first {
            latestWeight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
        }
    }

    // MARK: - Fetch Latest Body Fat (Zepp Scale)

    public func fetchLatestBodyFat() async throws {
        guard let bfType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else { return }

        var descriptor = HKSampleQueryDescriptor<HKQuantitySample>(
            predicates: [.quantitySample(type: bfType)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )

        let results = try await descriptor.result(for: healthStore)
        if let sample = results.first {
            latestBodyFat = sample.quantity.doubleValue(for: .percent()) * 100
        }
    }

    // MARK: - Refresh All

    public func refreshAll() async {
        do {
            try await fetchTodaySteps()
            try await fetchTodayActiveEnergy()
            try await fetchLatestHeartRate()
            try await fetchLatestWeight()
            try await fetchLatestBodyFat()
        } catch {
            print("[HealthDebug] HealthKit refresh error: \(error)")
        }
    }
}
