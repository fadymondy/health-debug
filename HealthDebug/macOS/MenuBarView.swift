import SwiftUI
import SwiftData
import AppKit
import HealthDebugKit

struct MenuBarView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var hydration = HydrationManager.shared
    @StateObject private var standTimer = StandTimerManager.shared
    @StateObject private var caffeine = CaffeineManager.shared
    @StateObject private var shutdown = ShutdownManager.shared
    @StateObject private var health = HealthKitManager.shared
    @Query(UserProfile.currentDescriptor()) private var profiles: [UserProfile]
    @Query(SleepConfig.currentDescriptor()) private var sleepConfigs: [SleepConfig]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header
            HStack {
                Image(systemName: "heart.text.clipboard")
                    .foregroundStyle(.accent)
                    .font(.title3)
                Text("Health Debug")
                    .font(.headline)
                Spacer()
                Text("v\(HealthDebugKit.version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            Divider()

            // Live metrics
            VStack(spacing: 8) {
                metricRow(icon: "drop.fill", color: .blue,
                    label: "Hydration",
                    value: profiles.first.map { "\(hydration.todayTotal) / \($0.dailyWaterGoalMl) ml" } ?? "\(hydration.todayTotal) / 2500 ml")

                metricRow(icon: "timer", color: .orange,
                    label: "Focus",
                    value: "\(standTimer.todayCompleted) / \(StandTimerManager.dailyTarget) sessions")

                metricRow(icon: "figure.walk", color: .teal,
                    label: "Steps",
                    value: health.stepCount >= 1000
                        ? String(format: "%.1fk / 10k", health.stepCount / 1000)
                        : "\(Int(health.stepCount)) / 10,000")

                metricRow(icon: "cup.and.saucer.fill", color: .brown,
                    label: "Caffeine",
                    value: "\(caffeine.todayCleanCount) clean · \(caffeine.todaySugarCount) sugar")

                if shutdown.state == .active {
                    metricRow(icon: "moon.fill", color: .orange,
                        label: "Shutdown",
                        value: ShutdownManager.formatCountdown(shutdown.secondsUntilSleep) + " until sleep")
                }
            }
            .padding(10)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))

            // Quick actions
            GlassEffectContainer {
                HStack(spacing: 8) {
                    Button("+250ml") {
                        hydration.logWater(250, source: "menubar", context: context, profile: profiles.first)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.blue)
                    .controlSize(.small)

                    if standTimer.phase == .idle {
                        Button("Start Focus") {
                            standTimer.startCycle()
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.orange)
                        .controlSize(.small)
                    } else if standTimer.phase == .work {
                        Button("Take Break") {
                            standTimer.startBreak()
                        }
                        .buttonStyle(.glass)
                        .controlSize(.small)
                    }
                }
            }

            Divider()

            // Footer actions
            Button("Open Health Debug") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows
                    .filter { $0.canBecomeMain && $0.styleMask.contains(.titled) }
                    .first?
                    .makeKeyAndOrderFront(nil)
            }
            .buttonStyle(.glass)
            .controlSize(.small)
            .frame(maxWidth: .infinity)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            hydration.refresh(context: context)
            if let p = profiles.first { hydration.dailyGoal = p.dailyWaterGoalMl }
            caffeine.refresh(context: context)
            standTimer.refreshTodayCount(context: context)
            shutdown.startCountdown(config: sleepConfigs.first)
        }
    }

    private func metricRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 18)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}

#Preview {
    MenuBarView()
        .frame(width: 320)
        .padding()
}
