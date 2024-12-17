import Foundation
import SwiftUI
import SwiftData

enum AuthenticationState: Equatable {
    case idle
    case authenticating
    case authenticated
    case unauthenticated
    case error(String)
}

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published private(set) var state: AuthenticationState = .idle
    @Published private(set) var currentUser: User?
    private let networkManager = NetworkManager.shared
    private var modelContext: ModelContext?
    
    init() {
        self.state = .unauthenticated
        
        if networkManager.loadTokenFromKeychain(forKey: "accessToken") != nil {
            Task {
                await verifyToken()
            }
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        
        // Try to restore authentication state
        let descriptor = FetchDescriptor<AuthState>()
        if let authState = try? context.fetch(descriptor).first {
            if authState.isAuthenticated {
                self.state = .authenticated
                if let userId = authState.userId, let userEmail = authState.userEmail {
                    self.currentUser = User(id: userId, email: userEmail)
                }
            } else {
                self.state = .unauthenticated
            }
        } else {
            // Create initial auth state
            let authState = AuthState()
            context.insert(authState)
            try? context.save()
            self.state = .unauthenticated
        }
    }
    
    private func setState(_ newState: AuthenticationState) {
        state = newState
        
        guard let modelContext = modelContext else { return }
        
        // Update persistent auth state
        let descriptor = FetchDescriptor<AuthState>()
        guard let authState = try? modelContext.fetch(descriptor).first else { return }
        
        switch newState {
        case .authenticated:
            authState.isAuthenticated = true
            authState.userId = currentUser?.id
            authState.userEmail = currentUser?.email
        case .unauthenticated:
            authState.isAuthenticated = false
            authState.userId = nil
            authState.userEmail = nil
        default:
            break
        }
        
        try? modelContext.save()
    }
    
    private func verifyToken() async {
        if networkManager.loadTokenFromKeychain(forKey: "accessToken") != nil {
            do {
                // Try to fetch watchlist as a way to verify token
                _ = try await networkManager.fetchWatchlist()
                setState(.authenticated)
            } catch {
                setState(.unauthenticated)
            }
        } else {
            setState(.unauthenticated)
        }
    }
    
    func signIn(username: String, password: String) async {
        guard !username.isEmpty, !password.isEmpty else {
            setState(.error("Please fill in all fields"))
            return
        }
        
        setState(.authenticating)
        
        do {
            let response = try await networkManager.login(email: username, password: password)
            currentUser = User(id: String(response.user.pk), email: response.user.email)
            setState(.authenticated)
        } catch let error as NetworkError {
            switch error {
            case .unauthorized:
                setState(.error("Invalid email or password"))
            case .serverError(let message):
                setState(.error(message))
            default:
                setState(.error("An unexpected error occurred"))
            }
        } catch {
            setState(.error("An unexpected error occurred"))
        }
    }
    
    func signUp(username: String, email: String, password: String) async {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            setState(.error("Please fill in all fields"))
            return
        }
        
        guard isValidEmail(email) else {
            setState(.error("Please enter a valid email address"))
            return
        }
        
        guard isValidPassword(password) else {
            setState(.error("Password must be at least 8 characters long and contain at least one number"))
            return
        }
        
        setState(.authenticating)
        
        do {
            // First register the user
            let registerResponse = try await networkManager.register(username: username, email: email, password: password)
            
            // Then login to get the tokens
            let loginResponse = try await networkManager.login(email: registerResponse.email, password: password)
            currentUser = User(id: String(loginResponse.user.pk), email: loginResponse.user.email)
            setState(.authenticated)
        } catch let error as NetworkError {
            switch error {
            case .serverError(let message):
                setState(.error(message))
            case .unauthorized:
                setState(.error("Invalid credentials."))
            default:
                setState(.error("An unexpected error occurred"))
            }
        } catch {
            setState(.error("An unexpected error occurred"))
        }
    }
    
    func signInWithApple(userId: String, email: String?, fullName: String?) async {
        setState(.authenticating)
        
        // TODO: Implement actual Apple Sign In
        // This is a placeholder for the actual implementation
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            if let email = email {
                currentUser = User(id: userId, email: email)
                setState(.authenticated)
            } else {
                setState(.error("Could not get email from Apple Sign In"))
            }
        } catch {
            setState(.error("Apple Sign In failed"))
        }
    }
    
    func signInWithGoogle(idToken: String) async {
        setState(.authenticating)
        
        // TODO: Implement actual Google Sign In
        // This is a placeholder for the actual implementation
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            setState(.error("Google Sign In not implemented yet"))
        } catch {
            setState(.error("Google Sign In failed"))
        }
    }
    
    func signOut() async {
        do {
            try await networkManager.logout()
            currentUser = nil
            setState(.unauthenticated)
        } catch {
            print("Error during logout:", error)
            // Still clear the user and tokens even if the server request fails
            currentUser = nil
            setState(.unauthenticated)
        }
    }
    
    // MARK: - Validation Helpers
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters and contains at least one number
        let passwordRegex = "^(?=.*[0-9]).{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: password)
    }
}

// Extension to provide a preview instance
extension AuthenticationViewModel {
    static var preview: AuthenticationViewModel {
        let viewModel = AuthenticationViewModel()
        viewModel.currentUser = User(id: "preview", email: "preview@example.com")
        viewModel.state = .authenticated
        return viewModel
    }
} 
