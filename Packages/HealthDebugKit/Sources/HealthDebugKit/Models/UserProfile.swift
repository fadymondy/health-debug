import Foundation
import SwiftData

@Model
public final class UserProfile {
    // Physical Metrics
    public var weightKg: Double // Baseline: 108
    public var heightCm: Double // 179
    public var muscleMassKg: Double // 66.9

    // Zepp Scale Metrics
    public var metabolicAge: Int // Baseline: 53, Target: < 35
    public var visceralFat: Int // Baseline: 14, Target: < 10
    public var bodyWaterPercent: Double // Baseline: 46.7%, Target: > 55%

    // Work Window
    public var workStartHour: Int // default: 9
    public var workStartMinute: Int // default: 0
    public var workEndHour: Int // default: 19
    public var workEndMinute: Int // default: 0

    // Targets
    public var targetWeightKg: Double
    public var targetVisceralFat: Int
    public var targetBodyWaterPercent: Double
    public var targetMetabolicAge: Int

    // Hydration
    public var dailyWaterGoalMl: Int // default: 2500

    // Notification: Daily Weight Check-In
    public var weightAlertEnabled: Bool    // default: true
    public var weightAlertHour: Int        // default: 7 (7am)
    public var weightAlertMinute: Int      // default: 0
    public var weightAlertDelayMinutes: Int // delay after wake time, default: 5

    // Metadata
    public var onboardingCompleted: Bool
    public var lastUpdated: Date

    public init(
        weightKg: Double = 108.0,
        heightCm: Double = 179.0,
        muscleMassKg: Double = 66.9,
        metabolicAge: Int = 53,
        visceralFat: Int = 14,
        bodyWaterPercent: Double = 46.7,
        workStartHour: Int = 9,
        workStartMinute: Int = 0,
        workEndHour: Int = 19,
        workEndMinute: Int = 0,
        targetWeightKg: Double = 90.0,
        targetVisceralFat: Int = 10,
        targetBodyWaterPercent: Double = 55.0,
        targetMetabolicAge: Int = 35,
        dailyWaterGoalMl: Int = 2500,
        weightAlertEnabled: Bool = true,
        weightAlertHour: Int = 7,
        weightAlertMinute: Int = 0,
        weightAlertDelayMinutes: Int = 5,
        onboardingCompleted: Bool = false,
        lastUpdated: Date = .now
    ) {
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.muscleMassKg = muscleMassKg
        self.metabolicAge = metabolicAge
        self.visceralFat = visceralFat
        self.bodyWaterPercent = bodyWaterPercent
        self.workStartHour = workStartHour
        self.workStartMinute = workStartMinute
        self.workEndHour = workEndHour
        self.workEndMinute = workEndMinute
        self.targetWeightKg = targetWeightKg
        self.targetVisceralFat = targetVisceralFat
        self.targetBodyWaterPercent = targetBodyWaterPercent
        self.targetMetabolicAge = targetMetabolicAge
        self.dailyWaterGoalMl = dailyWaterGoalMl
        self.weightAlertEnabled = weightAlertEnabled
        self.weightAlertHour = weightAlertHour
        self.weightAlertMinute = weightAlertMinute
        self.weightAlertDelayMinutes = weightAlertDelayMinutes
        self.onboardingCompleted = onboardingCompleted
        self.lastUpdated = lastUpdated
    }

    public var bmi: Double {
        let heightM = heightCm / 100.0
        return weightKg / (heightM * heightM)
    }

    public var workWindowHours: Double {
        let startMinutes = workStartHour * 60 + workStartMinute
        let endMinutes = workEndHour * 60 + workEndMinute
        return Double(endMinutes - startMinutes) / 60.0
    }
}
