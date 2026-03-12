import SwiftUI
import SwiftData
import HealthDebugKit

struct StandTimerView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var pomodoro = PomodoroManager.shared
    @Query(PomodoroSession.todayDescriptor()) private var todaySessions: [PomodoroSession]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                cycleDotsRow
                timerRing
                phaseLabel
                actionButtons
                statsRow
                if !todaySessions.isEmpty {
                    sessionHistoryCard
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(LocalizedStringKey("Pomodoro"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            pomodoro.refreshTodayCount(context: context)
            Task { await pomodoro.requestNotificationPermission() }
        }
    }

    // MARK: - Cycle Dots

    private var cycleDotsRow: some View {
        HStack(spacing: 8) {
            ForEach(0..<PomodoroManager.cyclesBeforeLongBreak, id: \.self) { idx in
                Circle()
                    .fill(idx < pomodoro.cyclePosition ? AppTheme.primary : Color.secondary.opacity(0.2))
                    .frame(width: 10, height: 10)
                    .animation(.easeInOut, value: pomodoro.cyclePosition)
            }
            Image(systemName: "bolt.fill")
                .font(.caption)
                .foregroundStyle(AppTheme.accent.opacity(0.7))
        }
        .padding(.top, 4)
    }

    // MARK: - Timer Ring

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 14)
                .frame(width: 230, height: 230)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(ringColor.gradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 230, height: 230)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: ringProgress)

            VStack(spacing: 6) {
                Image(systemName: phaseIcon)
                    .font(.system(size: 26))
                    .foregroundStyle(ringColor)
                    .symbolEffect(.pulse, isActive: pomodoro.phase == .idle && pomodoro.secondsRemaining == 0)

                Text(timerText)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text(phaseSubtext)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Phase Label

    private var phaseLabel: some View {
        Text(phaseName)
            .font(.title3.weight(.semibold))
            .foregroundStyle(ringColor)
            .animation(.easeInOut, value: pomodoro.phase)
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        switch pomodoro.phase {
        case .idle:
            if pomodoro.secondsRemaining == 0 && pomodoro.completedCycles > 0 {
                // Work session just ended — show break choice
                breakPrompt
            } else {
                // True idle — start
                GlassEffectContainer {
                    Button { pomodoro.startCycle() } label: {
                        Label("Start Focus", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(AppTheme.primary)
                    .controlSize(.large)
                }
                .padding(.horizontal)
            }

        case .work:
            GlassEffectContainer {
                HStack(spacing: 16) {
                    Button { pomodoro.stopCycle() } label: {
                        Label("Stop", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)

                    Button { pomodoro.beginWalk(context: context) } label: {
                        Label("Take Break", systemImage: "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(AppTheme.secondary)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal)

        case .shortBreak, .longBreak:
            GlassEffectContainer {
                HStack(spacing: 16) {
                    Button { pomodoro.skipBreak() } label: {
                        Label("Skip Break", systemImage: "forward.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal)

        case .standAlert:
            breakPrompt
        }
    }

    private var breakPrompt: some View {
        VStack(spacing: 12) {
            Text("Session Complete!")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.primary)

            let isLong = pomodoro.cyclePosition == 0 && pomodoro.completedCycles > 0
            Text(isLong ? "Time for a 15-min long break — you earned it." : "Take a 5-min short break before your next session.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            GlassEffectContainer {
                HStack(spacing: 16) {
                    Button { pomodoro.skipBreak() } label: {
                        Label("Skip", systemImage: "forward.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)

                    Button {
                        let isLongBreak = pomodoro.cyclePosition == 0 && pomodoro.completedCycles > 0
                        if isLongBreak {
                            // start long break
                        } else {
                            pomodoro.startCycle()
                        }
                    } label: {
                        Label("Start Break", systemImage: "cup.and.heat.waves.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(AppTheme.accent)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statPill(
                value: "\(pomodoro.todayCompleted)",
                label: "Today",
                icon: "checkmark.circle.fill",
                color: AppTheme.primary
            )
            statPill(
                value: "\(pomodoro.completedCycles)",
                label: "Sets",
                icon: "bolt.circle.fill",
                color: AppTheme.accent
            )
            statPill(
                value: "\(PomodoroManager.dailyTarget - pomodoro.todayCompleted)",
                label: "Remaining",
                icon: "target",
                color: AppTheme.secondary
            )
        }
        .padding(.horizontal)
    }

    private func statPill(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassEffect(.regular.tint(color.opacity(0.1)), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Session History

    private var sessionHistoryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Today's Sessions", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundStyle(AppTheme.secondary)
            Divider()
            ForEach(todaySessions.prefix(8)) { session in
                HStack {
                    Image(systemName: phaseIcon(for: session.phase))
                        .foregroundStyle(phaseColor(for: session.phase))
                    Text(session.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                    Spacer()
                    Text(session.completed ? phaseDisplayName(for: session.phase) : "interrupted")
                        .font(.caption)
                        .foregroundStyle(session.completed ? phaseColor(for: session.phase) : .secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    // MARK: - Computed helpers

    private var ringProgress: CGFloat {
        let total: TimeInterval
        switch pomodoro.phase {
        case .idle:         return pomodoro.secondsRemaining == 0 && pomodoro.completedCycles > 0 ? 1.0 : 0
        case .work:         total = PomodoroManager.workDurationSeconds
        case .standAlert:   return 1.0
        case .shortBreak:   total = PomodoroManager.shortBreakSeconds
        case .longBreak:    total = PomodoroManager.longBreakSeconds
        }
        let elapsed = total - pomodoro.secondsRemaining
        return CGFloat(max(0, min(1, elapsed / total)))
    }

    private var ringColor: Color {
        switch pomodoro.phase {
        case .idle:         return .secondary
        case .work:         return AppTheme.primary
        case .standAlert:   return AppTheme.accent
        case .shortBreak:   return AppTheme.accent
        case .longBreak:    return AppTheme.secondary
        }
    }

    private var phaseIcon: String {
        switch pomodoro.phase {
        case .idle:         return "timer"
        case .work:         return "brain.head.profile"
        case .standAlert:   return "figure.stand"
        case .shortBreak:   return "cup.and.heat.waves.fill"
        case .longBreak:    return "bed.double.fill"
        }
    }

    private var phaseName: String {
        switch pomodoro.phase {
        case .idle:         return NSLocalizedString("Ready", comment: "")
        case .work:         return NSLocalizedString("Focus", comment: "")
        case .standAlert:   return NSLocalizedString("Stand Up!", comment: "")
        case .shortBreak:   return NSLocalizedString("Short Break", comment: "")
        case .longBreak:    return NSLocalizedString("Long Break", comment: "")
        }
    }

    private var phaseSubtext: String {
        switch pomodoro.phase {
        case .idle:         return NSLocalizedString("Tap to start", comment: "")
        case .work:         return NSLocalizedString("Stay focused", comment: "")
        case .standAlert:   return NSLocalizedString("Time to move", comment: "")
        case .shortBreak:   return NSLocalizedString("Stretch & breathe", comment: "")
        case .longBreak:    return NSLocalizedString("Rest well", comment: "")
        }
    }

    private var timerText: String {
        let secs = Int(pomodoro.secondsRemaining)
        let m = secs / 60
        let s = secs % 60
        return String(format: "%d:%02d", m, s)
    }

    private func phaseIcon(for phase: String) -> String {
        switch phase {
        case "work":        return "brain.head.profile"
        case "shortBreak":  return "cup.and.heat.waves.fill"
        case "longBreak":   return "bed.double.fill"
        default:            return "timer"
        }
    }

    private func phaseColor(for phase: String) -> Color {
        switch phase {
        case "work":        return AppTheme.primary
        case "shortBreak":  return AppTheme.accent
        case "longBreak":   return AppTheme.secondary
        default:            return .secondary
        }
    }

    private func phaseDisplayName(for phase: String) -> String {
        switch phase {
        case "work":        return NSLocalizedString("Focus", comment: "")
        case "shortBreak":  return NSLocalizedString("Short Break", comment: "")
        case "longBreak":   return NSLocalizedString("Long Break", comment: "")
        default:            return phase
        }
    }
}
