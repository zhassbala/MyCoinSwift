import Foundation
import SwiftUI

enum AuthenticationState: Equatable {
    case authenticated
    case unauthenticated
    case authenticating
    case error(String)
    
    static func == (lhs: AuthenticationState, rhs: AuthenticationState) -> Bool {
        switch (lhs, rhs) {
        case (.authenticated, .authenticated),
             (.unauthenticated, .unauthenticated),
             (.authenticating, .authenticating):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var state: AuthenticationState = .unauthenticated
    @Published var currentUser: User?
    private let networkManager = NetworkManager.shared
    
    var isAuthenticated: Bool {
        currentUser != nil && state == .authenticated
    }
    
    init() {
        // Check if we have a stored token
        if networkManager.loadTokenFromKeychain(forKey: "accessToken") != nil {
            // TODO: Validate token with backend or decode JWT if available
            state = .authenticated
        }
    }
    
    func signIn(username: String, password: String) async {
        guard !username.isEmpty, !password.isEmpty else {
            state = .error("Please fill in all fields")
            return
        }
        
        state = .authenticating
        
        do {
            let response = try await networkManager.login(username: username, password: password)
            currentUser = User(id: String(response.user.pk), email: response.user.email)
            state = .authenticated
        } catch NetworkError.unauthorized {
            state = .error("Invalid username or password")
        } catch NetworkError.serverError(let message) {
            state = .error(message)
        } catch {
            state = .error("An unexpected error occurred")
        }
    }
    
    func signUp(username: String, email: String, password: String) async {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            state = .error("Please fill in all fields")
            return
        }
        
        guard isValidEmail(email) else {
            state = .error("Please enter a valid email address")
            return
        }
        
        guard isValidPassword(password) else {
            state = .error("Password must be at least 8 characters long and contain at least one number")
            return
        }
        
        state = .authenticating
        
        do {
            let registerResponse = try await networkManager.register(name: username, email: email, password: password)
            let loginResponse = try await networkManager.login(username: registerResponse.email, password: password)
            currentUser = User(id: String(loginResponse.user.pk), email: loginResponse.user.email)
            state = .authenticated
        } catch NetworkError.serverError(let message) {
            state = .error(message)
        } catch {
            state = .error("An unexpected error occurred")
        }
    }
    
    func signInWithApple(userId: String, email: String?, fullName: String?) async {
        state = .authenticating
        
        // Mock implementation for Apple Sign In
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
            let user = User(id: userId, email: email ?? "apple_user@example.com")
            currentUser = user
            networkManager.setTokens(
                accessToken: "mock_apple_access_token",
                refreshToken: "mock_apple_refresh_token"
            )
            state = .authenticated
        } catch {
            state = .error("Apple Sign In failed")
        }
    }
    
    func signInWithGoogle(userId: String, email: String, fullName: String) async {
        state = .authenticating
        
        // Mock implementation for Google Sign In
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
            let user = User(id: userId, email: email)
            currentUser = user
            networkManager.setTokens(
                accessToken: "mock_google_access_token",
                refreshToken: "mock_google_refresh_token"
            )
            state = .authenticated
        } catch {
            state = .error("Google Sign In failed")
        }
    }
    
    func signOut() async {
        do {
            try await networkManager.logout()
        } catch {
            print("Error during logout:", error)
        }
        currentUser = nil
        state = .unauthenticated
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
