import Foundation
import LocalAuthentication

/// Handles Face ID / Touch ID / Touch ID on Mac after the user has already
/// authenticated with Firebase at least once. Credentials are stored in Keychain
/// (via UserDefaults as a simple "biometric locked" flag — the Firebase session
/// persists automatically; biometrics just gates the UI unlock).
@MainActor
final class BiometricAuth: ObservableObject {
    static let shared = BiometricAuth()

    @Published var isUnlocked = false
    @Published var biometricError: String?

    private let context = LAContext()

    /// Whether the device supports Face ID or Touch ID.
    var isBiometricAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    var biometricType: String {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return "None" }
        switch ctx.biometryType {
        case .faceID:   return "Face ID"
        case .touchID:  return "Touch ID"
        case .opticID:  return "Optic ID"
        @unknown default: return "Biometrics"
        }
    }

    private let lockedKey = "biometric_locked"

    /// Called on every app foreground after Firebase confirms user is signed in.
    var requiresBiometric: Bool {
        get { UserDefaults.standard.bool(forKey: lockedKey) }
        set { UserDefaults.standard.set(newValue, forKey: lockedKey) }
    }

    private init() {}

    /// Lock the app — called on backgrounding or sign-in.
    func lock() {
        guard isBiometricAvailable && requiresBiometric else {
            isUnlocked = true  // biometric disabled or unavailable — stay open
            return
        }
        isUnlocked = false
    }

    /// Prompt for Face ID / Touch ID to unlock.
    func authenticate() async {
        guard isBiometricAvailable else {
            isUnlocked = true
            return
        }
        biometricError = nil
        let ctx = LAContext()
        do {
            let success = try await ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Health Debug"
            )
            isUnlocked = success
            if !success { biometricError = "Authentication failed" }
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .appCancel, .systemCancel:
                break  // user dismissed — don't show error
            case .biometryNotAvailable, .biometryNotEnrolled:
                isUnlocked = true  // fallback: just unlock
            default:
                biometricError = error.localizedDescription
            }
        } catch {
            biometricError = error.localizedDescription
        }
    }

    /// Enable / disable biometric lock from settings.
    func toggleBiometric(enabled: Bool) async -> Bool {
        guard isBiometricAvailable else { return false }
        // Require one successful biometric verification to enable.
        if enabled {
            let ctx = LAContext()
            do {
                let ok = try await ctx.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "Enable biometric lock"
                )
                if ok { requiresBiometric = true }
                return ok
            } catch { return false }
        } else {
            requiresBiometric = false
            isUnlocked = true
            return true
        }
    }
}
