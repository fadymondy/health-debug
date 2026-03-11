import SwiftUI
import HealthDebugKit

struct MenuBarView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.clipboard")
                Text("Health Debug")
                    .font(.headline)
                Spacer()
                Text("v\(HealthDebugKit.version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)
                Text("Hydration: 0 / 2500 ml")
                    .font(.subheadline)
            }

            HStack {
                Image(systemName: "figure.stand")
                    .foregroundStyle(.green)
                Text("Stand: 0 / 6 sessions")
                    .font(.subheadline)
            }

            Divider()

            Button("+ 250ml Water") {
                // Will be implemented in Hydration feature
            }
            .buttonStyle(.borderedProminent)

            Divider()

            Button("Quit Health Debug") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 280)
    }
}

#Preview {
    MenuBarView()
}
