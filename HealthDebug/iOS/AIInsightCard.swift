import SwiftUI
import SwiftData
import HealthDebugKit

/// Reusable AI insight card that fetches and displays a domain-specific health tip.
struct AIInsightCard: View {
    let domain: AIInsightEngine.Domain
    @Environment(\.modelContext) private var context
    @StateObject private var engine = AIInsightEngine.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppTheme.gradient)
                Text("AI Insight")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.primary)
                Spacer()
                if engine.isLoading(domain) {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Button {
                        Task {
                            await engine.generate(
                                for: domain,
                                context: context,
                                profile: profiles.first,
                                sleepConfig: sleepConfigs.first,
                                force: true
                            )
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let insight = engine.insights[domain] {
                MarkdownView(content: insight)
            } else if engine.isLoading(domain) {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Analyzing your data...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                Text("Tap refresh to get an AI-powered insight.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .onAppear {
            Task {
                await engine.generate(
                    for: domain,
                    context: context,
                    profile: profiles.first,
                    sleepConfig: sleepConfigs.first
                )
            }
        }
    }
}
