import SwiftUI
import SwiftData
import HealthDebugKit

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var context

    @State private var workStart: Date
    @State private var workEnd: Date
    @State private var sleepTime: Date
    @State private var shutdownHours: Int
    @State private var weightAlertTime: Date

    init(profile: UserProfile, sleepConfig: SleepConfig?) {
        self.profile = profile
        let cal = Calendar.current
        let sc = sleepConfig ?? SleepConfig()
        _workStart = State(initialValue: cal.date(from: DateComponents(hour: profile.workStartHour, minute: profile.workStartMinute))!)
        _workEnd = State(initialValue: cal.date(from: DateComponents(hour: profile.workEndHour, minute: profile.workEndMinute))!)
        _sleepTime = State(initialValue: cal.date(from: DateComponents(hour: sc.targetSleepHour, minute: sc.targetSleepMinute))!)
        _shutdownHours = State(initialValue: sc.shutdownWindowHours)
        _weightAlertTime = State(initialValue: cal.date(from: DateComponents(hour: profile.weightAlertHour, minute: profile.weightAlertMinute)) ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Body Composition") {
                    fieldRow("Weight", value: $profile.weightKg, unit: "kg")
                    fieldRow("Height", value: $profile.heightCm, unit: "cm")
                    fieldRow("Muscle Mass", value: $profile.muscleMassKg, unit: "kg")
                    intFieldRow("Metabolic Age", value: $profile.metabolicAge, unit: "years")
                    intFieldRow("Visceral Fat", value: $profile.visceralFat, unit: "level")
                    fieldRow("Body Water", value: $profile.bodyWaterPercent, unit: "%")
                }

                Section("Targets") {
                    fieldRow("Target Weight", value: $profile.targetWeightKg, unit: "kg")
                    intFieldRow("Target Visceral Fat", value: $profile.targetVisceralFat, unit: "level")
                    fieldRow("Target Body Water", value: $profile.targetBodyWaterPercent, unit: "%")
                    intFieldRow("Target Metabolic Age", value: $profile.targetMetabolicAge, unit: "years")
                }

                Section("Work Window") {
                    DatePicker("Start", selection: $workStart, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $workEnd, displayedComponents: .hourAndMinute)
                    Stepper(value: $profile.dailyWaterGoalMl, in: 1000...5000, step: 250) {
                        HStack(spacing: 4) {
                            Text("Daily Water Goal")
                            Text(verbatim: "\(profile.dailyWaterGoalMl)")
                                .foregroundStyle(.secondary)
                            Text("ml")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Toggle(isOn: $profile.weightAlertEnabled) {
                        Label(String(localized: "Daily Weight Check-In"), systemImage: "scalemass.fill")
                    }
                    if profile.weightAlertEnabled {
                        DatePicker(
                            String(localized: "Wake Time"),
                            selection: $weightAlertTime,
                            displayedComponents: .hourAndMinute
                        )
                        Stepper(value: $profile.weightAlertDelayMinutes, in: 1...30) {
                            HStack(spacing: 4) {
                                Text(String(localized: "Remind after"))
                                Text(verbatim: "\(profile.weightAlertDelayMinutes)")
                                    .foregroundStyle(.secondary)
                                Text(String(localized: "min"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text(String(localized: "Weight Alert"))
                } footer: {
                    Text(String(localized: "Reminds you to step on your smart scale each morning."))
                        .font(.caption)
                }

                Section {
                    Toggle(isOn: $profile.hygieneAlertEnabled) {
                        Label(String(localized: "Post-Meal Hygiene Reminder"), systemImage: "hand.raised.fill")
                    }
                    if profile.hygieneAlertEnabled {
                        Stepper(value: $profile.hygieneAlertDelayMinutes, in: 1...30) {
                            HStack(spacing: 4) {
                                Text(String(localized: "Remind after"))
                                Text(verbatim: "\(profile.hygieneAlertDelayMinutes)")
                                    .foregroundStyle(.secondary)
                                Text(String(localized: "min"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text(String(localized: "Hygiene Alert"))
                } footer: {
                    Text(String(localized: "Reminds you to wash hands and brush teeth after each meal."))
                        .font(.caption)
                }

                Section {
                    Toggle(isOn: $profile.pomodoroStartAlertEnabled) {
                        Label(String(localized: "Work Start Alert"), systemImage: "play.circle.fill")
                    }
                    if profile.pomodoroStartAlertEnabled {
                        Stepper(value: $profile.pomodoroStartLeadMinutes, in: 5...60, step: 5) {
                            HStack(spacing: 4) {
                                Text(String(localized: "Lead time"))
                                Text(verbatim: "\(profile.pomodoroStartLeadMinutes)")
                                    .foregroundStyle(.secondary)
                                Text(String(localized: "min before"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Toggle(isOn: $profile.pomodoroEndAlertEnabled) {
                        Label(String(localized: "Work End Alert"), systemImage: "stop.circle.fill")
                    }
                    if profile.pomodoroEndAlertEnabled {
                        Stepper(value: $profile.pomodoroEndLeadMinutes, in: 5...60, step: 5) {
                            HStack(spacing: 4) {
                                Text(String(localized: "Lead time"))
                                Text(verbatim: "\(profile.pomodoroEndLeadMinutes)")
                                    .foregroundStyle(.secondary)
                                Text(String(localized: "min before"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text(String(localized: "Pomodoro Alerts"))
                } footer: {
                    Text(String(localized: "Alerts you before your work day starts and ends so you can prepare your Pomodoro cycle."))
                        .font(.caption)
                }

                Section("Sleep") {
                    DatePicker("Bedtime", selection: $sleepTime, displayedComponents: .hourAndMinute)
                    Stepper(value: $shutdownHours, in: 1...6) {
                        HStack(spacing: 4) {
                            Text("Shutdown Window")
                            Text(verbatim: "\(shutdownHours)")
                                .foregroundStyle(.secondary)
                            Text("hours")
                                .foregroundStyle(.secondary)
                            Text("before")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    HStack {
                        Text("BMI")
                        Spacer()
                        Text(String(format: "%.1f", profile.bmi))
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Work Hours")
                        Spacer()
                        HStack(spacing: 2) {
                            Text(String(format: "%.1f", profile.workWindowHours))
                            Text("hours")
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .tint(AppTheme.primary)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .tint(AppTheme.primary)
    }

    private func fieldRow(_ label: LocalizedStringKey, value: Binding<Double>, unit: LocalizedStringKey) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, value: value, format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
        }
    }

    private func intFieldRow(_ label: LocalizedStringKey, value: Binding<Int>, unit: LocalizedStringKey) -> some View {
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

    private func save() {
        let cal = Calendar.current
        let ws = cal.dateComponents([.hour, .minute], from: workStart)
        profile.workStartHour = ws.hour ?? 9
        profile.workStartMinute = ws.minute ?? 0

        let we = cal.dateComponents([.hour, .minute], from: workEnd)
        profile.workEndHour = we.hour ?? 19
        profile.workEndMinute = we.minute ?? 0

        let wa = cal.dateComponents([.hour, .minute], from: weightAlertTime)
        profile.weightAlertHour = wa.hour ?? 7
        profile.weightAlertMinute = wa.minute ?? 0

        profile.lastUpdated = .now

        let sc = cal.dateComponents([.hour, .minute], from: sleepTime)
        if let existingSleep = try? context.fetch(SleepConfig.currentDescriptor()).first {
            existingSleep.targetSleepHour = sc.hour ?? 23
            existingSleep.targetSleepMinute = sc.minute ?? 0
            existingSleep.shutdownWindowHours = shutdownHours
            existingSleep.lastUpdated = .now
        }

        try? context.save()

        Task {
            await WeightAlertScheduler.shared.reschedule(profile: profile)
            await PomodoroAlertScheduler.shared.reschedule(profile: profile)
        }

        dismiss()
    }
}
