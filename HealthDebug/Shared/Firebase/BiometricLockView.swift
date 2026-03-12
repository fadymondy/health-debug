import SwiftUI

/// Shown when the app is locked after backgrounding.
/// Prompts for Face ID / Touch ID and shows a manual unlock button as fallback.
struct BiometricLockView: View {
    @EnvironmentObject private var biometric: BiometricAuth
    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: biometricIcon)
                .font(.system(size: 72))
                .foregroundStyle(AppTheme.primary.gradient)
                .padding()
                .glassEffect(.regular.tint(AppTheme.primary.opacity(0.15)), in: .circle)

            Text("Health Debug")
                .font(.largeTitle.bold())

            Text("Locked")
                .font(.title3)
                .foregroundStyle(.secondary)

            if let error = biometric.biometricError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await biometric.authenticate() }
            } label: {
                Label("Unlock with \(biometric.biometricType)", systemImage: biometricIcon)
                    .font(.headline)
                    .frame(maxWidth: 280)
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.primary)
            .controlSize(.large)

            // Sign out option if biometrics completely fails
            Button("Sign Out Instead") {
                biometric.isUnlocked = true  // release lock first
                auth.signOut()
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(32)
        .onAppear {
            Task { await biometric.authenticate() }
        }
    }

    private var biometricIcon: String {
        switch biometric.biometricType {
        case "Face ID":  return "faceid"
        case "Touch ID": return "touchid"
        default:         return "lock.fill"
        }
    }
}
