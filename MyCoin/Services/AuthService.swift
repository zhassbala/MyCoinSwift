import Foundation

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func register(email: String, password: String, firstName: String, lastName: String) async throws -> User
    func logout() async throws
    func getCurrentUser() async throws -> User
}

class AuthService: AuthServiceProtocol {
    private let apiClient: APIClientProtocol
    private let tokenService: TokenServiceProtocol
    
    init(apiClient: APIClientProtocol, tokenService: TokenServiceProtocol) {
        self.apiClient = apiClient
        self.tokenService = tokenService
    }
    
    func login(email: String, password: String) async throws -> User {
        let loginRequest = LoginRequest(username: email, password: password)
        
        let endpoint = APIEndpoint(
            path: "/auth/login/",
            method: .post,
            body: loginRequest,
            requiresAuth: false
        )
        
        let response: AuthResponse = try await apiClient.request(endpoint)
        try tokenService.saveTokens(
            access: response.accessToken,
            refresh: response.refreshToken,
            accessExpiration: ISO8601DateFormatter().date(from: response.accessTokenExpiration) ?? Date(),
            refreshExpiration: ISO8601DateFormatter().date(from: response.refreshTokenExpiration) ?? Date()
        )
        
        return User(
            id: response.user.pk,
            email: response.user.email,
            firstName: response.user.firstName,
            lastName: response.user.lastName
        )
    }
    
    func register(email: String, password: String, firstName: String, lastName: String) async throws -> User {
        let registerRequest = RegisterRequest(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName
        )
        
        let endpoint = APIEndpoint(
            path: "/auth/register/",
            method: .post,
            body: registerRequest,
            requiresAuth: false
        )
        
        let response: AuthResponse = try await apiClient.request(endpoint)
        try tokenService.saveTokens(
            access: response.accessToken,
            refresh: response.refreshToken,
            accessExpiration: ISO8601DateFormatter().date(from: response.accessTokenExpiration) ?? Date(),
            refreshExpiration: ISO8601DateFormatter().date(from: response.refreshTokenExpiration) ?? Date()
        )
        
        return User(
            id: response.user.pk,
            email: response.user.email,
            firstName: response.user.firstName,
            lastName: response.user.lastName
        )
    }
    
    func logout() async throws {
        let endpoint = APIEndpoint(path: "/auth/logout/", method: .post)
        try await apiClient.request(endpoint)
        try tokenService.clearTokens()
    }
    
    func getCurrentUser() async throws -> User {
        let endpoint = APIEndpoint(path: "/auth/me/")
        let response: UserResponse = try await apiClient.request(endpoint)
        
        return User(
            id: response.pk,
            email: response.email,
            firstName: response.firstName,
            lastName: response.lastName
        )
    }
}

// Request Models
struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
        case firstName = "first_name"
        case lastName = "last_name"
    }
} 
