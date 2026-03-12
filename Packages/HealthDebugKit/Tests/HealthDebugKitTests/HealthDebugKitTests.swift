import Testing
import Foundation
@testable import HealthDebugKit

@Test func versionIsSet() {
    #expect(HealthDebugKit.version == "1.0.0")
}

@Test func appNameIsCorrect() {
    #expect(HealthDebugKit.appName == "Health Debug")
}

// MARK: - WaterLog Tests

@Test func waterLogDefaultsTo250ml() {
    let log = WaterLog()
    #expect(log.amount == 250)
    #expect(log.source == "ios")
}

@Test func waterLogCustomAmount() {
    let log = WaterLog(amount: 500, source: "watch")
    #expect(log.amount == 500)
    #expect(log.source == "watch")
}

// MARK: - MealLog Tests

@Test func mealLogSafeByDefault() {
    let log = MealLog(name: "Grilled Chicken")
    #expect(log.isSafe == true)
    #expect(log.triggers.isEmpty)
    #expect(log.category == FoodCategory.protein.rawValue)
}

@Test func mealLogUnsafeWithTriggers() {
    let log = MealLog(
        name: "Falafel",
        category: .snack,
        isSafe: false,
        triggers: [.ibsGerd, .fattyLiver]
    )
    #expect(log.isSafe == false)
    #expect(log.triggers.count == 2)
    #expect(log.triggers.contains("IBS/GERD"))
    #expect(log.triggers.contains("Fatty Liver"))
}

// MARK: - CaffeineLog Tests

@Test func caffeineRedBullIsSugarBased() {
    let log = CaffeineLog(type: .redBull)
    #expect(log.isSugarBased == true)
    #expect(log.type == "Red Bull")
}

@Test func caffeineColdBrewIsClean() {
    #expect(CaffeineType.coldBrew.isClean == true)
    #expect(CaffeineType.coldBrew.isSugarBased == false)
}

@Test func caffeineMatchaIsClean() {
    #expect(CaffeineType.matcha.isClean == true)
    #expect(CaffeineType.matcha.isSugarBased == false)
}

@Test func caffeineAllCleanTypes() {
    let cleanTypes: [CaffeineType] = [.coldBrew, .matcha, .greenTea, .espresso, .blackCoffee]
    for type in cleanTypes {
        #expect(type.isClean == true, "Expected \(type.rawValue) to be clean")
        #expect(type.isSugarBased == false, "Expected \(type.rawValue) to not be sugar-based")
    }
}

// MARK: - StandSession Tests

@Test func standSessionDefaults() {
    let session = StandSession()
    #expect(session.durationSeconds == 180)
    #expect(session.completed == false)
}

// MARK: - SleepConfig Tests

@Test func sleepConfigDefaults() {
    let config = SleepConfig()
    #expect(config.targetSleepHour == 23)
    #expect(config.targetSleepMinute == 0)
    #expect(config.shutdownWindowHours == 4)
}

@Test func sleepConfigShutdownTime() {
    let config = SleepConfig(targetSleepHour: 23, targetSleepMinute: 0, shutdownWindowHours: 4)
    let shutdown = config.shutdownStartTime
    #expect(shutdown.hour == 19)
    #expect(shutdown.minute == 0)
}

@Test func sleepConfigShutdownWrapsAroundMidnight() {
    let config = SleepConfig(targetSleepHour: 1, targetSleepMinute: 0, shutdownWindowHours: 4)
    let shutdown = config.shutdownStartTime
    #expect(shutdown.hour == 21)
}

// MARK: - UserProfile Tests

@Test func userProfileBaseline() {
    let profile = UserProfile()
    #expect(profile.weightKg == 108.0)
    #expect(profile.heightCm == 179.0)
    #expect(profile.muscleMassKg == 66.9)
    #expect(profile.metabolicAge == 53)
    #expect(profile.visceralFat == 14)
    #expect(profile.bodyWaterPercent == 46.7)
    #expect(profile.dailyWaterGoalMl == 2500)
    #expect(profile.onboardingCompleted == false)
}

@Test func userProfileBMI() {
    let profile = UserProfile()
    let expectedBMI = 108.0 / (1.79 * 1.79)
    #expect(abs(profile.bmi - expectedBMI) < 0.01)
}

@Test func userProfileWorkWindow() {
    let profile = UserProfile(workStartHour: 9, workEndHour: 19)
    #expect(profile.workWindowHours == 10.0)
}

@Test func userProfileTargets() {
    let profile = UserProfile()
    #expect(profile.targetWeightKg == 90.0)
    #expect(profile.targetVisceralFat == 10)
    #expect(profile.targetBodyWaterPercent == 55.0)
    #expect(profile.targetMetabolicAge == 35)
}

// MARK: - FoodCategory Tests

@Test func foodCategoryAllCases() {
    #expect(FoodCategory.allCases.count == 5)
}

// MARK: - TriggerType Tests

@Test func triggerTypeAllCases() {
    #expect(TriggerType.allCases.count == 3)
    #expect(TriggerType.ibsGerd.rawValue == "IBS/GERD")
    #expect(TriggerType.gout.rawValue == "Gout")
    #expect(TriggerType.fattyLiver.rawValue == "Fatty Liver")
}
