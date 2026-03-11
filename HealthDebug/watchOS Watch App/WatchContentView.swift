import SwiftUI
import HealthDebugKit

struct WatchContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text("Hydration")
                                .font(.headline)
                            Text("0 / 2500 ml")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("+ 250ml") {
                        // Will be implemented in Hydration feature
                    }
                    .buttonStyle(.borderedProminent)
                }

                Section {
                    HStack {
                        Image(systemName: "figure.stand")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading) {
                            Text("Stand Timer")
                                .font(.headline)
                            Text("Next: --:--")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Health Debug")
        }
    }
}

#Preview {
    WatchContentView()
}
