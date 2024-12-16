import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingRegistration = false
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to MyCoin")
                    .font(.largeTitle)
                    .bold()
                
                Text("Your personal crypto investment assistant")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                }
                .padding(.vertical)
                
                if case .error(let message) = authViewModel.state {
                    Text(message)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button {
                    Task {
                        await authViewModel.signIn(email: email, password: password)
                    }
                } label: {
                    if case .authenticating = authViewModel.state {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(authViewModel.state == .authenticating)
                
                Button("Don't have an account? Sign Up") {
                    isShowingRegistration = true
                }
                .foregroundColor(.blue)
                
                Divider()
                    .padding(.vertical)
                
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                Task {
                                    await authViewModel.signInWithApple(
                                        userId: appleIDCredential.user,
                                        email: appleIDCredential.email,
                                        fullName: appleIDCredential.fullName?.givenName
                                    )
                                }
                            }
                        case .failure(let error):
                            print("Apple sign in failed:", error)
                        }
                    }
                )
                .frame(height: 44)
                
                Button(action: handleGoogleSignIn) {
                    HStack {
                        Image(systemName: "g.circle.fill")
                            .foregroundColor(.red)
                        Text("Sign in with Google")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding()
            .sheet(isPresented: $isShowingRegistration) {
                RegistrationView()
            }
        }
    }
    
    private func handleGoogleSignIn() {
        // TODO: Implement Google Sign In
        Task {
            await authViewModel.signInWithGoogle(
                userId: UUID().uuidString,
                email: "google@example.com",
                fullName: "Google User"
            )
        }
    }
}

struct RegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Security")) {
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
                
                if case .error(let message) = authViewModel.state {
                    Section {
                        Text(message)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button {
                        guard password == confirmPassword else {
                            // Show error
                            return
                        }
                        
                        Task {
                            await authViewModel.signUp(
                                email: email,
                                password: password,
                                fullName: fullName
                            )
                            if authViewModel.isAuthenticated {
                                dismiss()
                            }
                        }
                    } label: {
                        if case .authenticating = authViewModel.state {
                            ProgressView()
                        } else {
                            Text("Create Account")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(authViewModel.state == .authenticating)
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationViewModel())
} 