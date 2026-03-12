import SwiftUI
import SwiftData
import HealthDebugKit

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var step = 0
    @State private var profile = UserProfile()
    @State private var sleepConfig = SleepConfig()
    @State private var workStart = Calendar.current.date(from: DateComponents(hour: 9, minute: 0))!
    @State private var workEnd = Calendar.current.date(from: DateComponents(hour: 19, minute: 0))!
    @State private var sleepTime = Calendar.current.date(from: DateComponents(hour: 23, minute: 0))!

    let onComplete: () -> Void

    private let totalSteps = 4

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(step + 1), total: Double(totalSteps))
                    .tint(AppTheme.primary)
                    .padding(.horizontal)
                    .padding(.top, 8)

                TabView(selection: $step) {
                    welcomeStep.tag(0)
                    baselineStep.tag(1)
                    workWindowStep.tag(2)
                    sleepStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)

                GlassEffectContainer {
                    HStack {
                        if step > 0 {
                            Button("Back") { step -= 1 }
                                .buttonStyle(.glass)
                        }
                        Spacer()
                        if step < totalSteps - 1 {
                            Button("Next") { step += 1 }
                                .buttonStyle(.glassProminent)
                                .tint(AppTheme.primary)
                        } else {
                            Button("Get Started") { completeOnboarding() }
                                .buttonStyle(.glassProminent)
                                .tint(AppTheme.primary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image("AppIcon")
                .resizable()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 20)
            Text("Health Debug")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.gradient)
            Text("Your personal health optimization dashboard. Let's set up your baseline so we can track your progress.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding()
    }

    // MARK: - Step 2: Baseline Metrics

    private var baselineStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                sectionHeader(icon: "scalemass.fill", title: "Your Baseline", subtitle: "Current body composition from Zepp scale")

                VStack(spacing: 16) {
                    metricRow(label: "Weight", value: $profile.weightKg, unit: "kg")
                    metricRow(label: "Height", value: $profile.heightCm, unit: "cm")
                    metricRow(label: "Muscle Mass", value: $profile.muscleMassKg, unit: "kg")

                    Divider()

                    intRow(label: "Metabolic Age", value: $profile.metabolicAge, unit: "years")
                    intRow(label: "Visceral Fat", value: $profile.visceralFat, unit: "level")
                    metricRow(label: "Body Water", value: $profile.bodyWaterPercent, unit: "%")

                    Divider()

                    Text("Targets")
                        .font(.headline)
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    metricRow(label: "Target Weight", value: $profile.targetWeightKg, unit: "kg")
                    intRow(label: "Target Visceral Fat", value: $profile.targetVisceralFat, unit: "level")
                    metricRow(label: "Target Body Water", value: $profile.targetBodyWaterPercent, unit: "%")
                    intRow(label: "Target Metabolic Age", value: $profile.targetMetabolicAge, unit: "years")
                }
                .padding()
                .glassEffect(.regular.tint(AppTheme.primary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
            }
            .padding()
        }
    }

    // MARK: - Step 3: Work Window

    private var workWindowStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                sectionHeader(icon: "deskclock.fill", title: "Work Window", subtitle: "When do you work? We'll schedule stand reminders during this time.")

                VStack(spacing: 16) {
                    DatePicker("Work Start", selection: $workStart, displayedComponents: .hourAndMinute)
                    DatePicker("Work End", selection: $workEnd, displayedComponents: .hourAndMinute)

                    Divider()

                    HStack {
                        Text("Daily Water Goal")
                        Spacer()
                        Stepper("\(profile.dailyWaterGoalMl) ml", value: $profile.dailyWaterGoalMl, in: 1000...5000, step: 250)
                            .fixedSize()
                    }
                }
                .padding()
                .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
            }
            .padding()
        }
    }

    // MARK: - Step 4: Sleep

    private var sleepStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                sectionHeader(icon: "moon.zzz.fill", title: "Sleep Schedule", subtitle: "When do you want to be in bed? We'll trigger the GERD shutdown timer before this.")

                VStack(spacing: 16) {
                    DatePicker("Target Bedtime", selection: $sleepTime, displayedComponents: .hourAndMinute)

                    HStack {
                        Text("Shutdown Window")
                        Spacer()
                        Stepper("\(sleepConfig.shutdownWindowHours)h before bed", value: $sleepConfig.shutdownWindowHours, in: 1...6)
                            .fixedSize()
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Label("What this means", systemImage: "info.circle")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.secondary)
                        let shutdownHour = (Calendar.current.component(.hour, from: sleepTime) - sleepConfig.shutdownWindowHours + 24) % 24
                        Text("No eating after \(String(format: "%d:%02d", shutdownHour, Calendar.current.component(.minute, from: sleepTime))) PM to prevent acid reflux.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .glassEffect(.regular.tint(AppTheme.secondary.opacity(0.1)), in: RoundedRectangle(cornerRadius: 20))
            }
            .padding()
        }
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.gradient)
            Text(title)
                .font(.title2.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private func metricRow(label: String, value: Binding<Double>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, value: value, format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
        }
    }

    private func intRow(label: String, value: Binding<Int>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
        }
    }

    // MARK: - Complete

    private func completeOnboarding() {
        let workStartComponents = Calendar.current.dateComponents([.hour, .minute], from: workStart)
        profile.workStartHour = workStartComponents.hour ?? 9
        profile.workStartMinute = workStartComponents.minute ?? 0

        let workEndComponents = Calendar.current.dateComponents([.hour, .minute], from: workEnd)
        profile.workEndHour = workEndComponents.hour ?? 19
        profile.workEndMinute = workEndComponents.minute ?? 0

        let sleepComponents = Calendar.current.dateComponents([.hour, .minute], from: sleepTime)
        sleepConfig.targetSleepHour = sleepComponents.hour ?? 23
        sleepConfig.targetSleepMinute = sleepComponents.minute ?? 0
        sleepConfig.lastUpdated = .now

        profile.onboardingCompleted = true
        profile.lastUpdated = .now

        context.insert(profile)
        context.insert(sleepConfig)
        try? context.save()

        onComplete()
    }
}
