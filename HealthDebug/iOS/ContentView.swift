import SwiftUI
import HealthDebugKit

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "heart.text.clipboard")
                    .font(.system(size: 64))
                    .foregroundStyle(.accent)

                Text("Health Debug")
                    .font(.largeTitle.bold())

                Text("v\(HealthDebugKit.version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("System Boot Sequence...")
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Dashboard")
        }
    }
}

#Preview {
    ContentView()
}
