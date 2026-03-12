import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseCrashlytics
import GoogleSignIn
import Combine

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    nonisolated(unsafe) private var handle: AuthStateDidChangeListenerHandle?

    private init() {
        // Access Auth.auth() in init body — Firebase must be configured first.
        user = Auth.auth().currentUser
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                self?.user = user
                Crashlytics.crashlytics().setUserID(user?.uid ?? "")
            }
        }
    }

    var uid: String { user?.uid ?? "" }
    var isSignedIn: Bool { user != nil }

    // MARK: - Email/Password

    func signIn(email: String, password: String) async {
        isLoading = true; errorMessage = nil
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            user = result.user
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func signUp(email: String, password: String) async {
        isLoading = true; errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            user = result.user
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        isLoading = true; errorMessage = nil
        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                errorMessage = "Firebase not configured"; isLoading = false; return
            }
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

            #if os(iOS)
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.windows.first?.rootViewController else {
                errorMessage = "No root view controller"; isLoading = false; return
            }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: root)
            #elseif os(macOS)
            guard let window = NSApplication.shared.keyWindow else {
                errorMessage = "No key window"; isLoading = false; return
            }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
            #endif

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Missing Google ID token"; isLoading = false; return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            user = authResult.user
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        try? Auth.auth().signOut()
        user = nil
        Crashlytics.crashlytics().setUserID("")
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }
}
