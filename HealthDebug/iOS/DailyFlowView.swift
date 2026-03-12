import SwiftUI
import SwiftData
import HealthDebugKit

// MARK: - Shared Data Helper

/// Provides computed daily-flow checklist items from all managers.
/// Used by DailyFlowMetricCard, DailyFlowFullCard, and DailyFlowDetailView.
@MainActor
private struct DailyFlowData {
    let completedCount: Int
    let totalCount: Int
    let score: Double
    let scoreColor: Color
    let items: [(title: String, detail: String, isComplete: Bool, color: Color)]

    static func build(
        hydration: HydrationManager,
        nutrition: NutritionManager,
        caffeine: CaffeineManager,
        stand: StandTimerManager,
        shutdown: ShutdownManager,
        health: HealthKitManager
    ) -> DailyFlowData {
        let waterOk    = hydration.todayTotal >= 500
        let mealsLogged = nutrition.todayMeals.count >= 1
        let standOk    = stand.todayCompleted >= 2
        let caffeineOk = !caffeine.fattyLiverAlert
        let shutdownOk = shutdown.state != .violated
        let sleepOk    = health.sleepHours >= 6

        let items: [(String, String, Bool, Color)] = [
            (
                NSLocalizedString("Morning Hydration", comment: ""),
                String(format: NSLocalizedString("%d ml logged", comment: ""), hydration.todayTotal),
                waterOk,
                AppTheme.secondary
            ),
            (
                NSLocalizedString("Meals Logged", comment: ""),
                String(format: NSLocalizedString("%d meals today", comment: ""), nutrition.todayMeals.count),
                mealsLogged,
                AppTheme.primary
            ),
            (
                NSLocalizedString("Stand Sessions", comment: ""),
                "\(stand.todayCompleted)/\(StandTimerManager.dailyTarget) " + NSLocalizedString("complete", comment: ""),
                standOk,
                AppTheme.accent
            ),
            (
                NSLocalizedString("Caffeine Clean", comment: ""),
                caffeine.fattyLiverAlert
                    ? NSLocalizedString("Sugar-based detected", comment: "")
                    : String(format: NSLocalizedString("%d clean drinks", comment: ""), caffeine.todayCleanCount),
                caffeineOk,
                AppTheme.primary
            ),
            (
                NSLocalizedString("Shutdown Compliant", comment: ""),
                shutdown.state == .violated
                    ? NSLocalizedString("Rule broken", comment: "")
                    : NSLocalizedString("On track", comment: ""),
                shutdownOk,
                .orange
            ),
            (
                NSLocalizedString("Sleep Quality", comment: ""),
                String(format: NSLocalizedString("%.1fh last night", comment: ""), health.sleepHours),
                sleepOk,
                AppTheme.secondary
            ),
        ]

        let completed = items.filter(\.2).count
        let total = items.count
        let score = total > 0 ? Double(completed) / Double(total) : 0.0
        let scoreColor: Color = score >= 0.8 ? AppTheme.primary : score >= 0.5 ? .orange : .red

        return DailyFlowData(
            completedCount: completed,
            totalCount: total,
            score: score,
            scoreColor: scoreColor,
            items: items
        )
    }
}

// MARK: - A) DailyFlowMetricCard (2x2 pinned grid)

struct DailyFlowMetricCard: View {
    @StateObject private var hydration = HydrationManager.shared
    @StateObject private var nutrition = NutritionManager.shared
    @StateObject private var caffeine  = CaffeineManager.shared
    @StateObject private var stand     = StandTimerManager.shared
    @StateObject private var shutdown  = ShutdownManager.shared
    @StateObject private var health    = HealthKitManager.shared
    @Environment(\.modelContext) private var context

    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        let data = DailyFlowData.build(
            hydration: hydration,
            nutrition: nutrition,
            caffeine: caffeine,
            stand: stand,
            shutdown: shutdown,
            health: health
        )

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "checklist")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(LocalizedStringKey("Daily Flow"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(verbatim: "\(data.completedCount)/\(data.totalCount)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(data.scoreColor)
            }

            let pct = Int(data.score * 100)
            Text(
                data.completedCount == data.totalCount
                    ? LocalizedStringKey("All goals met")
                    : LocalizedStringKey("\(pct)% complete")
            )
            .font(.caption2)
            .foregroundStyle(data.scoreColor)
            .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(data.scoreColor.opacity(0.12))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(data.scoreColor)
                        .frame(width: geo.size.width * data.score, height: 3)
                        .animation(.spring(response: 0.5), value: data.score)
                }
            }
            .frame(height: 3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(data.scoreColor.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16))
        .allowsHitTesting(false)
    }
}

// MARK: - B) DailyFlowFullCard (unpinned full-width list)

struct DailyFlowFullCard: View {
    @StateObject private var hydration = HydrationManager.shared
    @StateObject private var nutrition = NutritionManager.shared
    @StateObject private var caffeine  = CaffeineManager.shared
    @StateObject private var stand     = StandTimerManager.shared
    @StateObject private var shutdown  = ShutdownManager.shared
    @StateObject private var health    = HealthKitManager.shared
    @Environment(\.modelContext) private var context

    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        let data = DailyFlowData.build(
            hydration: hydration,
            nutrition: nutrition,
            caffeine: caffeine,
            stand: stand,
            shutdown: shutdown,
            health: health
        )
        let statusText = data.score >= 0.8
            ? NSLocalizedString("On Track", comment: "")
            : data.score >= 0.5
                ? NSLocalizedString("Needs Attention", comment: "")
                : NSLocalizedString("Critical", comment: "")

        VStack(alignment: .leading, spacing: 0) {
            // Title row
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(LocalizedStringKey("Daily Flow"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 8)

            // Primary metric
            Text(verbatim: "\(data.completedCount)/\(data.totalCount) " + NSLocalizedString("goals", comment: ""))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(data.scoreColor)
                .padding(.horizontal, 16)

            // Detail
            Text(verbatim: String(format: NSLocalizedString("%.0f%% complete", comment: ""), data.score * 100))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 2)

            // Status pill
            Text(verbatim: statusText)
                .font(.caption2.bold())
                .foregroundStyle(data.scoreColor)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .glassEffect(.regular.tint(data.scoreColor.opacity(0.2)), in: Capsule())
                .padding(.horizontal, 16).padding(.top, 6)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(data.scoreColor.opacity(0.12))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(data.scoreColor)
                        .frame(width: geo.size.width * data.score, height: 4)
                        .animation(.spring(response: 0.5), value: data.score)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 16).padding(.top, 10)

            Spacer().frame(height: 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(data.scoreColor.opacity(0.07)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .allowsHitTesting(false)
    }
}

// MARK: - C) DailyFlowDetailView (full detail page)

struct DailyFlowDetailView: View {
    @StateObject private var hydration = HydrationManager.shared
    @StateObject private var nutrition = NutritionManager.shared
    @StateObject private var caffeine  = CaffeineManager.shared
    @StateObject private var stand     = StandTimerManager.shared
    @StateObject private var shutdown  = ShutdownManager.shared
    @StateObject private var health    = HealthKitManager.shared
    @StateObject private var rag       = HealthRAG.shared
    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    @Environment(\.layoutDirection) private var layoutDirection

    @State private var briefing = ""
    @State private var loadingBriefing = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        let data = DailyFlowData.build(
            hydration: hydration,
            nutrition: nutrition,
            caffeine: caffeine,
            stand: stand,
            shutdown: shutdown,
            health: health
        )

        ScrollView {
            VStack(spacing: 20) {
                progressRing(data: data)
                checklistSection(data: data)
                AIInsightCard(domain: .hydration)
                briefingSection(data: data)
            }
            .padding(.vertical)
        }
        .navigationTitle(LocalizedStringKey("Daily Flow"))
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Progress Ring

    private func progressRing(data: DailyFlowData) -> some View {
        ZStack {
            Circle()
                .stroke(data.scoreColor.opacity(0.15), lineWidth: 14)
                .frame(width: 200, height: 200)

            Circle()
                .trim(from: 0, to: CGFloat(data.score))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [data.scoreColor, data.scoreColor.opacity(0.4)]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: data.score)

            VStack(spacing: 4) {
                Image(systemName: "checklist")
                    .font(.title2)
                    .foregroundStyle(data.scoreColor)

                Text(verbatim: "\(data.completedCount)/\(data.totalCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(LocalizedStringKey("goals met"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Checklist Section

    private func checklistSection(data: DailyFlowData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey("Today's Goals"))
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

            VStack(spacing: 8) {
                ForEach(Array(data.items.enumerated()), id: \.offset) { _, item in
                    checklistRow(item: item)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func checklistRow(item: (title: String, detail: String, isComplete: Bool, color: Color)) -> some View {
        HStack(spacing: 14) {
            Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(item.isComplete ? item.color : Color.secondary.opacity(0.5))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(item.title))
                    .font(.subheadline.weight(.medium))
                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if item.isComplete {
                Image(systemName: "checkmark")
                    .font(.caption2.bold())
                    .foregroundStyle(item.color)
                    .padding(5)
                    .glassEffect(.regular.tint(item.color.opacity(0.2)), in: Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(
            .regular.tint(item.isComplete ? item.color.opacity(0.06) : Color.secondary.opacity(0.04)),
            in: RoundedRectangle(cornerRadius: 14)
        )
    }

    // MARK: - AI Briefing Section

    private func briefingSection(data: DailyFlowData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppTheme.secondary)
                Text(LocalizedStringKey("AI Morning Briefing"))
                    .font(.headline)
            }
            .padding(.horizontal, 16)

            if !briefing.isEmpty {
                Text(briefing)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.08)), in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
            } else {
                Button {
                    loadBriefing(data: data)
                } label: {
                    if loadingBriefing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.8)
                            Text(LocalizedStringKey("Loading..."))
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Label(
                            LocalizedStringKey("Get AI Daily Briefing"),
                            systemImage: "sparkles"
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.secondary)
                .controlSize(.regular)
                .disabled(loadingBriefing)
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Load Briefing

    private func loadBriefing(data: DailyFlowData) {
        loadingBriefing = true
        let summary = "Daily flow: \(data.completedCount)/\(data.totalCount) goals met. "
            + "Water: \(hydration.todayTotal)ml. "
            + "Meals: \(nutrition.todayMeals.count). "
            + "Stand: \(stand.todayCompleted) sessions. "
            + String(format: "Sleep: %.1fh.", health.sleepHours)
        Task {
            await rag.send(
                "Give me a brief 2-sentence morning health briefing based on this data: \(summary)",
                context: context,
                profile: profile,
                sleepConfig: sleepConfigs.first
            )
            await MainActor.run {
                briefing = rag.messages.last?.content ?? ""
                loadingBriefing = false
            }
        }
    }
}

// MARK: - Legacy alias (kept for backward compat during transition)

typealias DailyFlowCard = DailyFlowFullCard
