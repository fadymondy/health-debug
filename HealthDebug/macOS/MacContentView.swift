import SwiftUI
import HealthDebugKit

struct MacContentView: View {
    var body: some View {
        NavigationSplitView {
            List {
                Label("Dashboard", systemImage: "gauge.with.dots.needle.bottom.50percent")
                Label("Hydration", systemImage: "drop.fill")
                Label("Nutrition", systemImage: "fork.knife")
                Label("Focus", systemImage: "cup.and.saucer.fill")
                Label("Movement", systemImage: "figure.walk")
                Label("Analytics", systemImage: "chart.xyaxis.line")
            }
            .navigationTitle("Health Debug")
        } detail: {
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
        }
    }
}

#Preview {
    MacContentView()
}
