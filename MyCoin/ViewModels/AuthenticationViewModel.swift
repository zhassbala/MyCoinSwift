import Foundation
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var state: AuthenticationState = .idle
    @Published var error: String?
    @Published var currentUser: User?
    
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol = DependencyContainer.shared.authService) {
        self.authService = authService
        Task {
            await checkAuthenticationState()
        }
    }
    
    func login(email: String, password: String) {
        state = .loading
        error = nil
        
        Task {
            do {
                currentUser = try await authService.login(email: email, password: password)
                state = .authenticated
            } catch {
                self.error = error.localizedDescription
                state = .error
            }
        }
    }
    
    func register(email: String, password: String, firstName: String, lastName: String) {
        state = .loading
        error = nil
        
        Task {
            do {
                currentUser = try await authService.register(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName
                )
                state = .authenticated
            } catch {
                self.error = error.localizedDescription
                state = .error
            }
        }
    }
    
    func logout() {
        state = .loading
        error = nil
        
        Task {
            do {
                try await authService.logout()
                currentUser = nil
                state = .notAuthenticated
            } catch {
                self.error = error.localizedDescription
                state = .error
            }
        }
    }
    
    private func checkAuthenticationState() async {
        state = .loading
        
        do {
            currentUser = try await authService.getCurrentUser()
            state = .authenticated
        } catch {
            state = .notAuthenticated
        }
    }
} 