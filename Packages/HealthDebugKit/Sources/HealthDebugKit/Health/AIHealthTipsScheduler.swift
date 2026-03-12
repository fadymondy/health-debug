import Foundation
import SwiftData

/// Generates AI-driven health tip notifications and persists them to the Intelligence feed.
///
/// Called from the BGProcessingTask (aiTips). Generates a health tip using the
/// AIInsightEngine, delivers it as a push notification, and stores it as a
/// NotificationItem with aiTip=true so it appears in the Intelligence feed.
@MainActor
public final class AIHealthTipsScheduler {

    public static let shared = AIHealthTipsScheduler()
    private init() {}

    private static let idPrefix = "io.threex1.HealthDebug.alert.aiTip."

    /// Generate and deliver one AI health tip. Call from background task.
    public func generateAndDeliver(context: ModelContext, profile: UserProfile?, sleepConfig: SleepConfig?) async {
        // Use AIInsightEngine to get a dashboard-level insight
        let engine = AnalyticsEngine.shared
        let healthContext = engine.buildContext(context: context, profile: profile, sleepConfig: sleepConfig)

        let prompt = buildTipPrompt(healthContext: healthContext, profile: profile)

        do {
            let tip = try await AIService.shared.analyze(prompt: prompt)
            let cleanTip = tip.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanTip.isEmpty else { return }

            let notifID = Self.idPrefix + UUID().uuidString

            // Deliver as notification AND persist as AI feed item (aiTip: true)
            await NotificationManager.shared.schedule(
                id: notifID,
                title: String(localized: "AI Health Tip"),
                body: cleanTip,
                category: .aiTip,
                source: .ai,
                deepLink: "intelligence",
                aiTip: true
            )
        } catch {
            // Silently skip on failure — background task will retry on next schedule
        }
    }

    // MARK: - Prompt

    private func buildTipPrompt(healthContext: HealthContext, profile: UserProfile?) -> String {
        """
        Based on this health data, give ONE short, practical health tip (max 2 sentences). \
        Be specific and actionable. No greetings, no titles, just the tip.

        Water today: \(healthContext.hydration.totalMl)ml / \(healthContext.hydration.goalMl)ml goal
        Meals: \(healthContext.nutrition.totalMeals) (\(healthContext.nutrition.unsafeMeals) unsafe)
        Caffeine: \(healthContext.caffeine.totalDrinks) drinks
        Movement: \(healthContext.movement.completedWalks) walks
        Weight: \(String(format: "%.1f", profile?.weightKg ?? 0)) kg
        """
    }
}
