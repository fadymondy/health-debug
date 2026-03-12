import SwiftUI

struct AuthView: View {
    @StateObject private var auth = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.clipboard.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red.gradient)

            Text("Health Debug")
                .font(.largeTitle.bold())

            Text(isSignUp ? "Create Account" : "Sign In")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    #endif
                    .padding()
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))

                SecureField("Password", text: $password)
                    .padding()
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            }

            if let error = auth.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    if isSignUp {
                        await auth.signUp(email: email, password: password)
                    } else {
                        await auth.signIn(email: email, password: password)
                    }
                }
            } label: {
                if auth.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                }
            }
            .buttonStyle(.glassProminent)
            .tint(.red)
            .controlSize(.large)
            .disabled(email.isEmpty || password.count < 6 || auth.isLoading)

            Button(isSignUp ? "Already have an account? Sign In" : "No account? Sign Up") {
                isSignUp.toggle()
                auth.errorMessage = nil
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(maxWidth: 400)
    }
}
