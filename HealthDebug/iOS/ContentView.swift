import SwiftUI
import SwiftData
import HealthDebugKit

struct ContentView: View {
    @StateObject private var health = HealthKitManager.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !health.isAuthorized {
                        authCard
                    } else {
                        metricsGrid
                        zeppCard
                        sleepCard
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                if let profile = profiles.first {
                    ProfileSettingsView(profile: profile, sleepConfig: sleepConfigs.first)
                }
            }
            .refreshable {
                await health.refreshAll()
            }
        }
    }

    // MARK: - Auth Card

    private var authCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.secondary)
            Text("HealthKit Access Required")
                .font(.headline)
            Text("Tap to authorize reading your health data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Authorize HealthKit") {
                Task {
                    try? await health.requestAuthorization()
                    await health.refreshAll()
                }
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.primary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.3)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            MetricCard(icon: "figure.walk", title: "Steps", value: formatted(health.stepCount), color: AppTheme.primary)
            MetricCard(icon: "flame.fill", title: "Active Energy", value: "\(formatted(health.activeEnergy)) kcal", color: .orange)
            MetricCard(icon: "heart.fill", title: "Heart Rate", value: "\(formatted(health.heartRate)) bpm", color: .red)
            MetricCard(icon: "moon.zzz.fill", title: "Sleep", value: String(format: "%.1fh", health.sleepHours), color: AppTheme.secondary)
        }
        .padding(.horizontal)
    }

    // MARK: - Zepp Card

    private var zeppCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Zepp Scale", systemImage: "scalemass.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.primary)
            Divider()
            HStack {
                VStack(alignment: .leading) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f kg", health.zeppMetrics.weight))
                        .font(.title3.bold())
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Body Fat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f%%", health.zeppMetrics.bodyFatPercent))
                        .font(.title3.bold())
                }
            }
            if let date = health.zeppMetrics.lastUpdated {
                Text("Last synced: \(date.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Sleep Card

    private var sleepCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Last Night", systemImage: "bed.double.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.secondary)
            Divider()
            HStack {
                Text(String(format: "%.1f hours", health.sleepHours))
                    .font(.title3.bold())
                Spacer()
                sleepQualityBadge
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private var sleepQualityBadge: some View {
        let (label, color): (String, Color) = {
            switch health.sleepHours {
            case 7...: return ("Good", AppTheme.primary)
            case 5..<7: return ("Low", .orange)
            default: return ("Critical", .red)
            }
        }()
        return Text(label)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .glassEffect(.regular.tint(color.opacity(0.3)), in: Capsule())
            .foregroundStyle(color)
    }

    private func formatted(_ value: Double) -> String {
        value >= 1000
            ? String(format: "%.1fk", value / 1000)
            : String(format: "%.0f", value)
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular.tint(color.opacity(0.15)), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ContentView()
}
