import Foundation
import SwiftData

/// Generates domain-specific AI insights for each health screen.
/// Caches results to avoid redundant API calls.
@MainActor
public final class AIInsightEngine: ObservableObject {

    public static let shared = AIInsightEngine()

    public enum Domain: String, CaseIterable {
        case dashboard
        case hydration
        case nutrition
        case caffeine
        case shutdown
    }

    @Published public var insights: [Domain: String] = [:]
    @Published public var loading: Set<Domain> = []

    /// Timestamps of last generation per domain — avoids re-fetching within cooldown.
    private var lastGenerated: [Domain: Date] = [:]

    /// Minimum seconds between insight refreshes for a given domain.
    private static let cooldownSeconds: TimeInterval = 300 // 5 minutes

    private init() {}

    /// Whether an insight is currently being generated for this domain.
    public func isLoading(_ domain: Domain) -> Bool {
        loading.contains(domain)
    }

    /// Generate an insight for the given domain if stale or missing.
    public func generate(
        for domain: Domain,
        context: ModelContext,
        profile: UserProfile?,
        sleepConfig: SleepConfig?,
        force: Bool = false
    ) async {
        // Skip if already loading
        guard !loading.contains(domain) else { return }

        // Skip if within cooldown (unless forced)
        if !force, let last = lastGenerated[domain],
           Date.now.timeIntervalSince(last) < Self.cooldownSeconds {
            return
        }

        loading.insert(domain)
        defer { loading.remove(domain) }

        let engine = AnalyticsEngine.shared
        let healthContext = engine.buildContext(context: context, profile: profile, sleepConfig: sleepConfig)
        let prompt = buildDomainPrompt(domain: domain, healthContext: healthContext, profile: profile)

        do {
            let response = try await AIService.shared.analyze(prompt: prompt)
            insights[domain] = response.trimmingCharacters(in: .whitespacesAndNewlines)
            lastGenerated[domain] = .now
        } catch {
            // On failure, set a fallback message rather than leaving blank
            if insights[domain] == nil {
                insights[domain] = fallback(for: domain, healthContext: healthContext)
            }
        }
    }

    /// Clear cached insights (e.g. on pull-to-refresh).
    public func clearCache() {
        insights.removeAll()
        lastGenerated.removeAll()
    }

    // MARK: - Domain Prompts

    /// Returns a language instruction if the device language is Arabic.
    private var languageInstruction: String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return code == "ar" ? "\nRespond in Arabic (العربية). Use natural, simple Arabic." : ""
    }

    private func buildDomainPrompt(domain: Domain, healthContext: HealthContext, profile: UserProfile?) -> String {
        let base = "You are a health AI for the Health Debug app. Give ONE short insight (2-3 sentences max). Be specific using the data. No greetings or filler.\(languageInstruction)"

        switch domain {
        case .dashboard:
            return """
            \(base)
            Give a brief overall health status for today based on this data:
            - Water: \(healthContext.hydration.totalMl)/\(healthContext.hydration.goalMl) ml
            - Meals: \(healthContext.nutrition.safeMeals) safe, \(healthContext.nutrition.unsafeMeals) unsafe
            - Caffeine: \(healthContext.caffeine.cleanBased) clean, \(healthContext.caffeine.sugarBased) sugar
            - Stand sessions: \(healthContext.movement.completedWalks)/\(healthContext.movement.targetSessions)
            - Triggers: \(healthContext.nutrition.triggersHit.isEmpty ? "none" : healthContext.nutrition.triggersHit.joined(separator: ", "))
            Focus on what needs attention most right now.
            """

        case .hydration:
            let deficit = max(0, healthContext.hydration.goalMl - healthContext.hydration.totalMl)
            return """
            \(base)
            Hydration data: \(healthContext.hydration.totalMl) ml consumed, goal \(healthContext.hydration.goalMl) ml, deficit \(deficit) ml, \(healthContext.hydration.logCount) logs today.
            User weight: \(profile?.weightKg ?? 0) kg. Body water: \(profile?.bodyWaterPercent ?? 0)%.
            Give a hydration-specific tip. Mention uric acid flush for gout if behind.
            """

        case .nutrition:
            return """
            \(base)
            Nutrition data: \(healthContext.nutrition.totalMeals) meals, \(healthContext.nutrition.safeMeals) safe, \(healthContext.nutrition.unsafeMeals) unsafe.
            Triggers hit: \(healthContext.nutrition.triggersHit.isEmpty ? "none" : healthContext.nutrition.triggersHit.joined(separator: ", "))
            This user has GERD and must avoid trigger foods (fatty, spicy, acidic, caffeine-heavy).
            Give a nutrition safety tip based on today's eating.
            """

        case .caffeine:
            return """
            \(base)
            Caffeine data: \(healthContext.caffeine.totalDrinks) drinks, \(healthContext.caffeine.cleanBased) clean, \(healthContext.caffeine.sugarBased) sugar-based.
            User is transitioning from Red Bull to clean caffeine (matcha, green tea, black coffee).
            Give a caffeine transition tip. Mention liver health if sugar-based drinks detected.
            """

        case .shutdown:
            return """
            \(base)
            Sleep config: target sleep \(healthContext.sleep.targetHour):\(String(format: "%02d", healthContext.sleep.targetMinute)), shutdown window \(healthContext.sleep.shutdownWindowHours) hours before.
            User has GERD and sinus issues — eating before bed triggers acid reflux.
            Meals today: \(healthContext.nutrition.totalMeals). Unsafe: \(healthContext.nutrition.unsafeMeals).
            Give a shutdown compliance tip for GERD prevention tonight.
            """
        }
    }

    // MARK: - Fallbacks (when AI is unavailable)

    private func fallback(for domain: Domain, healthContext: HealthContext) -> String {
        switch domain {
        case .dashboard:
            let waterPct = healthContext.hydration.goalMl > 0 ? (healthContext.hydration.totalMl * 100 / healthContext.hydration.goalMl) : 0
            return "You're at \(waterPct)% of your water goal with \(healthContext.nutrition.safeMeals) safe meals logged. Keep it up!"

        case .hydration:
            let remaining = max(0, healthContext.hydration.goalMl - healthContext.hydration.totalMl)
            if remaining == 0 { return "Great job — you've hit your hydration goal! Uric acid flush is on track." }
            let glasses = (remaining + 249) / 250
            return "\(glasses) more glass\(glasses == 1 ? "" : "es") to hit your flush target. Stay consistent to keep uric acid levels low."

        case .nutrition:
            if healthContext.nutrition.unsafeMeals > 0 {
                return "You had \(healthContext.nutrition.unsafeMeals) unsafe meal\(healthContext.nutrition.unsafeMeals == 1 ? "" : "s") today. Stick to the whitelist to protect your GERD recovery."
            }
            return "All meals safe today. Your digestive system thanks you!"

        case .caffeine:
            if healthContext.caffeine.sugarBased > 0 {
                return "\(healthContext.caffeine.sugarBased) sugar-based drink\(healthContext.caffeine.sugarBased == 1 ? "" : "s") detected. Try swapping to matcha or green tea to protect your liver."
            }
            return "Clean caffeine only today — great progress on the Red Bull deprecation!"

        case .shutdown:
            return "Remember: no food within \(healthContext.sleep.shutdownWindowHours) hours of bedtime. Only water, chamomile, or anise tea allowed."
        }
    }
}
