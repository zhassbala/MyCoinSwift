import Foundation
import SwiftUI
import SwiftData

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
            // Token exists, try to verify it
            Task {
                await verifyToken()
            }
        }
    }
    
    private func verifyToken() async {
        if networkManager.loadTokenFromKeychain(forKey: "accessToken") != nil {
            do {
                // Try to fetch watchlist as a way to verify token
                _ = try await networkManager.fetchWatchlist()
                state = .authenticated
            } catch {
                state = .unauthenticated
            }
        } else {
            state = .unauthenticated
        }
    }
    
    func signIn(username: String, password: String) async {
        guard !username.isEmpty, !password.isEmpty else {
            state = .error("Please fill in all fields")
            return
        }
        
        state = .authenticating
        
        do {
            let response = try await networkManager.login(email: username, password: password)
            currentUser = User(id: String(response.user.pk), email: response.user.email)
            state = .authenticated
        } catch let error as NetworkError {
            switch error {
            case .unauthorized:
                state = .error("Invalid email or password")
            case .serverError(let message):
                state = .error(message)
            default:
                state = .error("An unexpected error occurred")
            }
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
            // First register the user
            let registerResponse = try await networkManager.register(username: username, email: email, password: password)
            
            // Then login to get the tokens
            let loginResponse = try await networkManager.login(email: email, password: password)
            currentUser = User(id: String(loginResponse.user.pk), email: loginResponse.user.email)
            state = .authenticated
        } catch let error as NetworkError {
            switch error {
            case .serverError(let message):
                state = .error(message)
            case .unauthorized:
                state = .error("Invalid credentials.")
            default:
                state = .error("An unexpected error occurred")
            }
        } catch {
            state = .error("An unexpected error occurred")
        }
    }
    
    func signInWithApple(userId: String, email: String?, fullName: String?) async {
        state = .authenticating
        
        // TODO: Implement actual Apple Sign In
        // This is a placeholder for the actual implementation
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            if let email = email {
                currentUser = User(id: userId, email: email)
                state = .authenticated
            } else {
                state = .error("Could not get email from Apple Sign In")
            }
        } catch {
            state = .error("Apple Sign In failed")
        }
    }
    
    func signInWithGoogle(idToken: String) async {
        state = .authenticating
        
        // TODO: Implement actual Google Sign In
        // This is a placeholder for the actual implementation
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            state = .error("Google Sign In not implemented yet")
        } catch {
            state = .error("Google Sign In failed")
        }
    }
    
    func signOut() async {
        do {
            try await networkManager.logout()
            currentUser = nil
            state = .unauthenticated
        } catch {
            print("Error during logout:", error)
            // Still clear the user and tokens even if the server request fails
            currentUser = nil
            state = .unauthenticated
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
