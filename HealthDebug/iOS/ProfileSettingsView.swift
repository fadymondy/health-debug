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

    init(profile: UserProfile, sleepConfig: SleepConfig?) {
        self.profile = profile
        let cal = Calendar.current
        let sc = sleepConfig ?? SleepConfig()
        _workStart = State(initialValue: cal.date(from: DateComponents(hour: profile.workStartHour, minute: profile.workStartMinute))!)
        _workEnd = State(initialValue: cal.date(from: DateComponents(hour: profile.workEndHour, minute: profile.workEndMinute))!)
        _sleepTime = State(initialValue: cal.date(from: DateComponents(hour: sc.targetSleepHour, minute: sc.targetSleepMinute))!)
        _shutdownHours = State(initialValue: sc.shutdownWindowHours)
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
                    Stepper("Water Goal: \(profile.dailyWaterGoalMl) ml", value: $profile.dailyWaterGoalMl, in: 1000...5000, step: 250)
                }

                Section("Sleep") {
                    DatePicker("Bedtime", selection: $sleepTime, displayedComponents: .hourAndMinute)
                    Stepper("Shutdown: \(shutdownHours)h before", value: $shutdownHours, in: 1...6)
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
                        Text(String(format: "%.1fh", profile.workWindowHours))
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

    private func fieldRow(_ label: String, value: Binding<Double>, unit: String) -> some View {
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

    private func intFieldRow(_ label: String, value: Binding<Int>, unit: String) -> some View {
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

        profile.lastUpdated = .now

        let sc = cal.dateComponents([.hour, .minute], from: sleepTime)
        if let existingSleep = try? context.fetch(SleepConfig.currentDescriptor()).first {
            existingSleep.targetSleepHour = sc.hour ?? 23
            existingSleep.targetSleepMinute = sc.minute ?? 0
            existingSleep.shutdownWindowHours = shutdownHours
            existingSleep.lastUpdated = .now
        }

        try? context.save()
        dismiss()
    }
}
