import Foundation
import FirebaseAuth
import Combine

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var user: User? = Auth.auth().currentUser
    @Published var isLoading = false
    @Published var errorMessage: String?

    nonisolated(unsafe) private var handle: AuthStateDidChangeListenerHandle?

    private init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                self?.user = user
            }
        }
    }

    var uid: String { user?.uid ?? "" }
    var isSignedIn: Bool { user != nil }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            user = result.user
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            user = result.user
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        try? Auth.auth().signOut()
        user = nil
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }
}
