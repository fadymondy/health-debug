import SwiftUI
import SwiftData
import HealthDebugKit

struct StandTimerView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var timer = StandTimerManager.shared
    @Query(StandSession.todayDescriptor()) private var todaySessions: [StandSession]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    timerRing
                    statusCard
                    todayProgressCard
                    if !todaySessions.isEmpty {
                        sessionHistoryCard
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Stand Timer")
            .onAppear {
                timer.refreshTodayCount(context: context)
                Task { await timer.requestNotificationPermission() }
            }
        }
    }

    // MARK: - Timer Ring

    private var timerRing: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 12)
                .frame(width: 220, height: 220)

            // Progress ring
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(ringColor.gradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: ringProgress)

            // Center content
            VStack(spacing: 6) {
                Image(systemName: timerIcon)
                    .font(.system(size: 28))
                    .foregroundStyle(ringColor)
                    .symbolEffect(.pulse, isActive: timer.state == .standAlert)

                Text(timerText)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(timerSubtext)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: 12) {
            switch timer.state {
            case .idle:
                GlassEffectContainer {
                    Button {
                        timer.startCycle()
                    } label: {
                        Label("Start Timer", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(AppTheme.primary)
                    .controlSize(.large)
                }

            case .sitting:
                GlassEffectContainer {
                    Button {
                        timer.stopCycle()
                    } label: {
                        Label("Stop Timer", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                }

            case .standAlert:
                VStack(spacing: 8) {
                    Text("Time to Stand!")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.primary)

                    Text("90 minutes of sitting completed.\nTake a 3-minute walk for insulin sensitivity.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .glassEffect(.regular.tint(AppTheme.primary.opacity(0.2)), in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

                GlassEffectContainer {
                    HStack(spacing: 16) {
                        Button {
                            timer.skipStand()
                        } label: {
                            Label("Skip", systemImage: "forward.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                        .controlSize(.large)

                        Button {
                            timer.beginWalk(context: context)
                        } label: {
                            Label("Start Walk", systemImage: "figure.walk")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(AppTheme.primary)
                        .controlSize(.large)
                    }
                }

            case .walking:
                VStack(spacing: 8) {
                    Text("Walking...")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.accent)

                    Text("Keep moving! Your body is thanking you.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .glassEffect(.regular.tint(AppTheme.accent.opacity(0.2)), in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
            }
        }
        .padding(.horizontal, timer.state == .standAlert || timer.state == .walking ? 0 : 16)
    }

    // MARK: - Today Progress

    private var todayProgressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Today's Progress", systemImage: "figure.stand")
                .font(.headline)
                .foregroundStyle(AppTheme.primary)
            Divider()
            HStack {
                Text("\(timer.todayCompleted)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("/ \(StandTimerManager.dailyTarget) sessions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                progressRing
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.primary.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private var progressRing: some View {
        let progress = min(Double(timer.todayCompleted) / Double(StandTimerManager.dailyTarget), 1.0)
        return ZStack {
            Circle()
                .stroke(AppTheme.primary.opacity(0.15), lineWidth: 6)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppTheme.primary.gradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.caption2.bold())
                .foregroundStyle(AppTheme.primary)
        }
        .frame(width: 50, height: 50)
    }

    // MARK: - Session History

    private var sessionHistoryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Sessions", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundStyle(AppTheme.secondary)
            Divider()
            ForEach(todaySessions.prefix(6)) { session in
                HStack {
                    Image(systemName: session.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(session.completed ? AppTheme.primary : .secondary)
                    Text(session.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                    Spacer()
                    Text(session.completed ? "3 min walk" : "skipped")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Computed Properties

    private var ringProgress: CGFloat {
        switch timer.state {
        case .idle:
            return 0
        case .sitting:
            return 1.0 - CGFloat(timer.sitSecondsRemaining / StandTimerManager.sitIntervalSeconds)
        case .standAlert:
            return 1.0
        case .walking:
            return CGFloat(StandTimerManager.walkDurationSeconds - timer.walkSecondsRemaining) / CGFloat(StandTimerManager.walkDurationSeconds)
        }
    }

    private var ringColor: Color {
        switch timer.state {
        case .idle: return .secondary
        case .sitting: return AppTheme.secondary
        case .standAlert: return .orange
        case .walking: return AppTheme.accent
        }
    }

    private var timerIcon: String {
        switch timer.state {
        case .idle: return "figure.stand"
        case .sitting: return "chair.fill"
        case .standAlert: return "bell.fill"
        case .walking: return "figure.walk"
        }
    }

    private var timerText: String {
        switch timer.state {
        case .idle:
            return formatTime(Int(StandTimerManager.sitIntervalSeconds))
        case .sitting:
            return formatTime(Int(timer.sitSecondsRemaining))
        case .standAlert:
            return "Stand!"
        case .walking:
            return formatTime(timer.walkSecondsRemaining)
        }
    }

    private var timerSubtext: String {
        switch timer.state {
        case .idle: return "Tap to start"
        case .sitting: return "Until next stand break"
        case .standAlert: return "Take a 3-min walk"
        case .walking: return "Keep walking"
        }
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
