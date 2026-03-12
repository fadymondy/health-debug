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

    // Notification: Post-Meal Hygiene Reminder
    public var hygieneAlertEnabled: Bool       // default: true
    public var hygieneAlertDelayMinutes: Int   // delay after meal log, default: 5

    // Notification: Pomodoro Start/End Alerts
    public var pomodoroStartAlertEnabled: Bool     // default: true
    public var pomodoroStartLeadMinutes: Int       // minutes before work start, default: 15
    public var pomodoroEndAlertEnabled: Bool       // default: true
    public var pomodoroEndLeadMinutes: Int         // minutes before work end, default: 15

    // Notification: Heart Rate Thresholds
    public var heartRateHighThreshold: Int    // default: 120 bpm
    public var heartRateLowThreshold: Int     // default: 45 bpm

    // Notification: Meal Reminder
    public var mealReminderEnabled: Bool      // default: true

    // Notification: Coffee Time
    public var coffeeAlertEnabled: Bool       // default: true
    public var coffeeAlertHour: Int           // default: 10
    public var coffeeAlertMinute: Int         // default: 0

    // Notification: Hydration Gap
    public var hydrationAlertEnabled: Bool    // default: true
    public var hydrationAlertGapMinutes: Int  // minutes without water before alert, default: 60

    // Notification: Movement / Stand-Up
    public var movementAlertEnabled: Bool         // default: true
    public var movementAlertIntervalMinutes: Int  // interval during work hours, default: 60

    // Notification: GERD Shutdown Lead
    public var gerdShutdownLeadMinutes: Int   // minutes before shutdown, default: 15

    // Personal Info
    public var name: String
    public var email: String
    public var bio: String
    public var avatarData: Data?

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
        hygieneAlertEnabled: Bool = true,
        hygieneAlertDelayMinutes: Int = 5,
        pomodoroStartAlertEnabled: Bool = true,
        pomodoroStartLeadMinutes: Int = 15,
        pomodoroEndAlertEnabled: Bool = true,
        pomodoroEndLeadMinutes: Int = 15,
        heartRateHighThreshold: Int = 120,
        heartRateLowThreshold: Int = 45,
        mealReminderEnabled: Bool = true,
        coffeeAlertEnabled: Bool = true,
        coffeeAlertHour: Int = 10,
        coffeeAlertMinute: Int = 0,
        hydrationAlertEnabled: Bool = true,
        hydrationAlertGapMinutes: Int = 60,
        movementAlertEnabled: Bool = true,
        movementAlertIntervalMinutes: Int = 60,
        gerdShutdownLeadMinutes: Int = 15,
        name: String = "",
        email: String = "",
        bio: String = "",
        avatarData: Data? = nil,
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
        self.hygieneAlertEnabled = hygieneAlertEnabled
        self.hygieneAlertDelayMinutes = hygieneAlertDelayMinutes
        self.pomodoroStartAlertEnabled = pomodoroStartAlertEnabled
        self.pomodoroStartLeadMinutes = pomodoroStartLeadMinutes
        self.pomodoroEndAlertEnabled = pomodoroEndAlertEnabled
        self.pomodoroEndLeadMinutes = pomodoroEndLeadMinutes
        self.heartRateHighThreshold = heartRateHighThreshold
        self.heartRateLowThreshold = heartRateLowThreshold
        self.mealReminderEnabled = mealReminderEnabled
        self.coffeeAlertEnabled = coffeeAlertEnabled
        self.coffeeAlertHour = coffeeAlertHour
        self.coffeeAlertMinute = coffeeAlertMinute
        self.hydrationAlertEnabled = hydrationAlertEnabled
        self.hydrationAlertGapMinutes = hydrationAlertGapMinutes
        self.movementAlertEnabled = movementAlertEnabled
        self.movementAlertIntervalMinutes = movementAlertIntervalMinutes
        self.gerdShutdownLeadMinutes = gerdShutdownLeadMinutes
        self.name = name
        self.email = email
        self.bio = bio
        self.avatarData = avatarData
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
