import SwiftUI
import SwiftData
import HealthDebugKit

// MARK: - Hydration Detail (replaced with DrinkBuilderView)

struct HydrationDetailView: View {
    var body: some View {
        DrinkBuilderView()
    }
}

// MARK: - Nutrition Detail (replaced with MealPlannerView)

struct NutritionDetailView: View {
    var body: some View {
        MealPlannerView()
    }
}

// MARK: - Caffeine Detail

struct CaffeineDetailView: View {
    var body: some View {
        CaffeineView()
    }
}

// MARK: - Shutdown Detail

struct ShutdownDetailView: View {
    var body: some View {
        ShutdownView()
    }
}

// MARK: - Stand Timer Detail

struct StandTimerDetailView: View {
    var body: some View {
        StandTimerView()
    }
}

// MARK: - Zepp / Weight Detail

struct ZeppDetailView: View {
    @StateObject private var health = HealthKitManager.shared
    @StateObject private var rag = HealthRAG.shared
    @Environment(\.modelContext) private var context
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                weightCard
                AIInsightCard(domain: .dashboard)
                smartActionsCard
            }
            .padding(.vertical)
        }
        .navigationTitle(LocalizedStringKey("Weight"))
        .navigationBarTitleDisplayMode(.large)
    }

    private var weightCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "scalemass.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.primary)
            HStack(spacing: 4) {
                Text(String(format: "%.1f", health.zeppMetrics.weight))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text(LocalizedStringKey("kg"))
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)
            }
            if let date = health.zeppMetrics.lastUpdated {
                HStack(spacing: 4) {
                    Text(LocalizedStringKey("Last synced"))
                    Text(date.formatted(.relative(presentation: .named)))
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private var smartActionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("Smart Actions"), systemImage: "sparkles")
                .font(.headline).foregroundStyle(AppTheme.primary)
            Divider()
            Button {
                Task {
                    await rag.send(
                        "Analyze my weight trend and give me health advice",
                        context: context,
                        profile: profile,
                        sleepConfig: nil
                    )
                }
            } label: {
                Label(LocalizedStringKey("Analyze my weight"), systemImage: "brain")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }
}

// Note: SleepDetailView is now defined in HealthMetricDetailViews.swift
