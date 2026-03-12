import SwiftUI
import SwiftData
import HealthDebugKit

// MARK: - HealthFeedCard

struct HealthFeedCard: View {
    let icon: String
    let title: String
    let color: Color
    let value: String
    let statusLabel: String
    let statusColor: Color
    let primaryActionLabel: String
    let primaryActionIcon: String
    let askAIQuery: String
    let primaryAction: () -> Void

    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    @State private var aiResponse = ""
    @State private var isLoadingAI = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(verbatim: title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(LocalizedStringKey(statusLabel))
                    .font(.caption2.bold())
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .glassEffect(.regular.tint(statusColor.opacity(0.2)), in: Capsule())
            }

            // Value
            Text(verbatim: value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(statusColor)

            // Action buttons row
            HStack(spacing: 8) {
                Button {
                    primaryAction()
                } label: {
                    Label(LocalizedStringKey(primaryActionLabel), systemImage: primaryActionIcon)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.glass).tint(color)

                if isLoadingAI {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text(LocalizedStringKey("Thinking…"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if aiResponse.isEmpty {
                    Button {
                        runAI()
                    } label: {
                        Label(LocalizedStringKey("Ask AI"), systemImage: "sparkles")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.glass).tint(AppTheme.secondary)
                }

                Spacer()
            }

            // Inline AI markdown response
            if !aiResponse.isEmpty {
                Divider()
                MarkdownView(content: aiResponse)
                    .font(.caption)
                HStack {
                    Spacer()
                    Button {
                        withAnimation { aiResponse = "" }
                    } label: {
                        Label(LocalizedStringKey("Clear"), systemImage: "xmark.circle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(color.opacity(0.07)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func runAI() {
        isLoadingAI = true
        let profile = profiles.first
        Task {
            let countBefore = HealthRAG.shared.messages.count
            await HealthRAG.shared.send(askAIQuery, context: context, profile: profile, sleepConfig: sleepConfigs.first)
            await MainActor.run {
                // Take the last assistant message added after our send
                let newMessages = HealthRAG.shared.messages.dropFirst(countBefore)
                aiResponse = newMessages.last(where: { $0.role == .assistant })?.content ?? ""
                isLoadingAI = false
            }
        }
    }
}

// MARK: - IntelligenceView

struct IntelligenceView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var ai = AIService.shared
    @StateObject private var analytics = AnalyticsEngine.shared
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var hydration = HydrationManager.shared
    @StateObject private var nutrition = NutritionManager.shared
    @StateObject private var caffeine = CaffeineManager.shared
    @StateObject private var standTimer = StandTimerManager.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    @State private var showAPISettings = false

    private var profile: UserProfile? { profiles.first }

    // MARK: - Health Score (0-100)

    private var healthScore: Int {
        var score = 0.0
        var components = 0.0

        // Hydration: % of daily goal
        let hydrationPct = profile.map {
            min(1.0, Double(hydration.todayTotal) / Double(max(1, $0.dailyWaterGoalMl)))
        } ?? min(1.0, Double(hydration.todayTotal) / 2500.0)
        score += hydrationPct * 20; components += 20

        // Nutrition safety score (0-100 → 0-20)
        score += (nutrition.safetyScore / 100.0) * 20; components += 20

        // Caffeine clean transition (0-100 → 0-20)
        score += (caffeine.cleanTransitionPercent / 100.0) * 20; components += 20

        // Stand sessions (completed / target → 0-20)
        let standPct = min(1.0, Double(standTimer.todayCompleted) / Double(StandTimerManager.dailyTarget))
        score += standPct * 20; components += 20

        // Sleep quality (0-8h target → 0-20)
        let sleepPct = min(1.0, health.sleepHours / 8.0)
        score += sleepPct * 20; components += 20

        guard components > 0 else { return 0 }
        return Int((score / components) * 100)
    }

    private var healthScoreColor: Color {
        switch healthScore {
        case 80...: return AppTheme.primary
        case 50..<80: return .orange
        default: return .red
        }
    }

    private var healthScoreLabel: String {
        switch healthScore {
        case 80...: return NSLocalizedString("Excellent", comment: "")
        case 60..<80: return NSLocalizedString("Good", comment: "")
        case 40..<60: return NSLocalizedString("Fair", comment: "")
        default: return NSLocalizedString("Needs Attention", comment: "")
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    healthScoreCard
                    feedSection
                    analyzeButton
                    if !analytics.lastAnalysis.isEmpty {
                        analysisSection
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(LocalizedStringKey("Intelligence"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAPISettings = true
                    } label: {
                        Image(systemName: ai.selectedProvider == .apple ? "apple.intelligence" : "cloud.fill")
                            .font(.subheadline)
                    }
                }
            }
            .sheet(isPresented: $showAPISettings) {
                APISettingsSheet()
            }
        }
        .onAppear {
            hydration.refresh(context: context)
            nutrition.refresh(context: context)
            caffeine.refresh(context: context)
            standTimer.refreshTodayCount(context: context)
        }
    }

    // MARK: - 1. Health Score Card

    private var healthScoreCard: some View {
        Button {
            runAnalysis()
        } label: {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey("Health Score"))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(LocalizedStringKey("Your health score today"))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    // Provider badge
                    HStack(spacing: 4) {
                        Image(systemName: ai.selectedProvider == .apple ? "apple.intelligence" : "cloud.fill")
                            .font(.caption2)
                        Text(ai.selectedProvider.rawValue)
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(ai.selectedProvider == .apple ? AppTheme.primary : AppTheme.accent)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: Capsule())
                }

                // Score ring + number
                HStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(healthScoreColor.opacity(0.15), lineWidth: 10)
                            .frame(width: 100, height: 100)
                        Circle()
                            .trim(from: 0, to: CGFloat(healthScore) / 100.0)
                            .stroke(healthScoreColor.gradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.6), value: healthScore)
                        VStack(spacing: 0) {
                            HStack(alignment: .lastTextBaseline, spacing: 2) {
                                Text(verbatim: "\(healthScore)")
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundStyle(healthScoreColor)
                                Text(LocalizedStringKey("/100"))
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        scoreComponentRow(icon: "drop.fill", label: "Hydration", color: AppTheme.secondary,
                            value: profile.map { min(1.0, Double(hydration.todayTotal) / Double(max(1, $0.dailyWaterGoalMl))) } ?? 0)
                        scoreComponentRow(icon: "fork.knife", label: "Nutrition", color: AppTheme.primary,
                            value: nutrition.safetyScore / 100.0)
                        scoreComponentRow(icon: "figure.stand", label: "Stands", color: AppTheme.accent,
                            value: min(1.0, Double(standTimer.todayCompleted) / Double(StandTimerManager.dailyTarget)))
                        scoreComponentRow(icon: "moon.zzz.fill", label: "Sleep", color: AppTheme.secondary,
                            value: min(1.0, health.sleepHours / 8.0))
                    }
                    Spacer()
                }

                HStack {
                    Text(verbatim: healthScoreLabel)
                        .font(.subheadline.bold())
                        .foregroundStyle(healthScoreColor)
                    Spacer()
                    if ai.isLoading {
                        ProgressView().controlSize(.small)
                        Text(LocalizedStringKey("Analyzing…"))
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Label(LocalizedStringKey("Tap to analyze"), systemImage: "sparkles")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(healthScoreColor.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .disabled(ai.isLoading)
    }

    private func scoreComponentRow(icon: String, label: String, color: Color, value: Double) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2).foregroundStyle(color)
                .frame(width: 16)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.15)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2).fill(color)
                        .frame(width: geo.size.width * max(0, min(1, value)), height: 4)
                        .animation(.spring(response: 0.5), value: value)
                }
            }
            .frame(height: 4)
            Text(LocalizedStringKey(label))
                .font(.caption2).foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
        }
    }

    // MARK: - 2. Feed Section

    private var feedSection: some View {
        VStack(spacing: 12) {
            HStack {
                Label(LocalizedStringKey("Health Feed"), systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primary)
                Spacer()
            }
            .padding(.horizontal)

            HealthFeedCard(
                icon: "drop.fill",
                title: NSLocalizedString("Hydration", comment: ""),
                color: AppTheme.secondary,
                value: profile.map { "\(hydration.todayTotal) ml / \($0.dailyWaterGoalMl) ml" }
                    ?? "\(hydration.todayTotal) ml / 2500 ml",
                statusLabel: profile.map { hydration.status(profile: $0).rawValue } ?? "–",
                statusColor: hydrationFeedColor,
                primaryActionLabel: NSLocalizedString("Log 250ml", comment: ""),
                primaryActionIcon: "drop.circle.fill",
                askAIQuery: "How is my hydration today? Give brief advice."
            ) {
                hydration.logWater(250, source: "feed", context: context, profile: profile)
            }

            HealthFeedCard(
                icon: "fork.knife",
                title: NSLocalizedString("Nutrition", comment: ""),
                color: nutritionFeedColor,
                value: "\(nutrition.todaySafeCount) \(NSLocalizedString("safe", comment: "")) · \(nutrition.todayUnsafeCount) \(NSLocalizedString("unsafe", comment: ""))",
                statusLabel: nutrition.safetyStatus.rawValue,
                statusColor: nutritionFeedColor,
                primaryActionLabel: NSLocalizedString("Log Meal", comment: ""),
                primaryActionIcon: "fork.knife.circle.fill",
                askAIQuery: "Analyze my nutrition today and suggest improvements."
            ) {}

            HealthFeedCard(
                icon: "cup.and.saucer.fill",
                title: NSLocalizedString("Caffeine", comment: ""),
                color: caffeineFeedColor,
                value: "\(caffeine.todayCleanCount) \(NSLocalizedString("clean", comment: "")) · \(caffeine.todaySugarCount) \(NSLocalizedString("sugar", comment: ""))",
                statusLabel: caffeine.transitionStatus.rawValue,
                statusColor: caffeineFeedColor,
                primaryActionLabel: NSLocalizedString("View Logs", comment: ""),
                primaryActionIcon: "list.bullet.circle.fill",
                askAIQuery: "Give me caffeine advice for today."
            ) {}

            HealthFeedCard(
                icon: "figure.walk",
                title: NSLocalizedString("Steps & Energy", comment: ""),
                color: AppTheme.primary,
                value: "\(formatDouble(health.stepCount)) \(NSLocalizedString("steps", comment: "")) · \(String(format: "%.0f", health.activeEnergy)) kcal",
                statusLabel: health.stepCount >= 10000 ? NSLocalizedString("Goal Met", comment: "") : NSLocalizedString("In Progress", comment: ""),
                statusColor: health.stepCount >= 10000 ? AppTheme.primary : .orange,
                primaryActionLabel: NSLocalizedString("View Detail", comment: ""),
                primaryActionIcon: "chart.bar.fill",
                askAIQuery: "How are my activity levels today? Any recommendations?"
            ) {}

            HealthFeedCard(
                icon: "moon.zzz.fill",
                title: NSLocalizedString("Sleep", comment: ""),
                color: sleepFeedColor,
                value: String(format: "%.1f hrs", health.sleepHours),
                statusLabel: sleepFeedLabel,
                statusColor: sleepFeedColor,
                primaryActionLabel: NSLocalizedString("View Detail", comment: ""),
                primaryActionIcon: "moon.circle.fill",
                askAIQuery: "Analyze my sleep quality and give advice."
            ) {}
        }
    }

    // MARK: - 3. Full Analysis

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(LocalizedStringKey("Full Analysis"), systemImage: "brain.head.profile.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primary)
                Spacer()
                Text(ai.selectedProvider.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Divider()
            MarkdownView(content: analytics.lastAnalysis)
                .textSelection(.enabled)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - 4. Analyze Button

    private var analyzeButton: some View {
        GlassEffectContainer {
            Button {
                runAnalysis()
            } label: {
                HStack {
                    if ai.isLoading {
                        ProgressView().controlSize(.small)
                        Text(ai.selectedProvider == .apple ? LocalizedStringKey("Analyzing on-device…") : LocalizedStringKey("Analyzing 72h of data…"))
                    } else {
                        Label(LocalizedStringKey("Analyze My Health"), systemImage: "brain.head.profile.fill")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.primary)
            .controlSize(.large)
            .disabled(ai.isLoading)
        }
        .padding(.horizontal)
    }

    // MARK: - Computed Feed Colors

    private var hydrationFeedColor: Color {
        guard let profile else { return AppTheme.secondary }
        switch hydration.status(profile: profile) {
        case .onTrack, .goalReached: return AppTheme.primary
        case .slightlyBehind: return .orange
        case .dehydrated: return .red
        }
    }

    private var nutritionFeedColor: Color {
        switch nutrition.safetyStatus {
        case .allSafe, .noMeals: return AppTheme.primary
        case .warning: return .orange
        case .critical: return .red
        }
    }

    private var caffeineFeedColor: Color {
        switch caffeine.transitionStatus {
        case .clean, .noIntake: return AppTheme.primary
        case .transitioning: return .orange
        case .redBullDependent: return .red
        }
    }

    private var sleepFeedLabel: String {
        switch health.sleepHours {
        case 7...: return NSLocalizedString("Good", comment: "")
        case 5..<7: return NSLocalizedString("Low", comment: "")
        default: return NSLocalizedString("Critical", comment: "")
        }
    }

    private var sleepFeedColor: Color {
        switch health.sleepHours {
        case 7...: return AppTheme.primary
        case 5..<7: return .orange
        default: return .red
        }
    }

    // MARK: - Actions

    private func runAnalysis() {
        let healthContext = analytics.buildContext(context: context, profile: profile, sleepConfig: sleepConfigs.first)
        let prompt = analytics.buildPrompt(healthContext: healthContext)
        Task {
            do {
                analytics.isAnalyzing = true
                let result = try await ai.analyze(prompt: prompt)
                analytics.lastAnalysis = result
                analytics.isAnalyzing = false
            } catch {
                analytics.lastAnalysis = "Error: \(error.localizedDescription)"
                analytics.isAnalyzing = false
            }
        }
    }

    private func formatDouble(_ value: Double) -> String {
        value >= 1000 ? String(format: "%.1fk", value / 1000) : String(format: "%.0f", value)
    }
}
