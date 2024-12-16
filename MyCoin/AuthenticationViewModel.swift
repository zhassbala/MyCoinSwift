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
    
    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            state = .error("Please fill in all fields")
            return
        }
        
        state = .authenticating
        
        // TODO: Implement actual sign in with backend
        // This is a mock implementation
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
            let user = User(id: UUID().uuidString, email: email)
            currentUser = user
            state = .authenticated
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func signUp(email: String, password: String, fullName: String) async {
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty else {
            state = .error("Please fill in all fields")
            return
        }
        
        state = .authenticating
        
        // TODO: Implement actual registration with backend
        // This is a mock implementation
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
            let user = User(id: UUID().uuidString, email: email)
            currentUser = user
            state = .authenticated
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func signInWithApple(userId: String, email: String?, fullName: String?) async {
        state = .authenticating
        
        // TODO: Implement actual Apple sign in with backend
        // This is a mock implementation
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
            let user = User(id: userId, email: email ?? "")
            currentUser = user
            state = .authenticated
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func signInWithGoogle(userId: String, email: String, fullName: String) async {
        state = .authenticating
        
        // TODO: Implement actual Google sign in with backend
        // This is a mock implementation
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
            let user = User(id: userId, email: email)
            currentUser = user
            state = .authenticated
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func signOut() {
        currentUser = nil
        state = .unauthenticated
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