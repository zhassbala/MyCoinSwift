import Foundation

// DependencyContainer is similar to React's Context or a dependency injection container in Node.js
// It's like having a global store for services, similar to:
// const container = {
//   apiClient: new APIClient(),
//   authService: new AuthService(),
//   tokenService: new TokenService(),
// }
class DependencyContainer {
    // Singleton pattern, similar to having a global store instance
    static let shared = DependencyContainer()
    
    // Base URL for API calls, like process.env.API_URL in Node.js
    private let baseURL = "http://127.0.0.1:8000/api" // Replace with your actual API base URL
    
    // MARK: - Services
    
    // Lazy initialization of services, similar to React.lazy() or lazy loading in JavaScript
    // These are like singleton instances of your services
    
    // API Client instance, like axios instance in JavaScript
    lazy var apiClient: APIClientProtocol = {
        APIClient(baseURL: baseURL, tokenService: tokenService)
    }()
    
    // Token service for auth token management
    // Similar to having an auth service in React/Node.js that manages JWT tokens
    lazy var tokenService: TokenServiceProtocol = {
        // This complex initialization handles circular dependency
        // Similar to how you might handle circular dependencies in Node.js modules
        TokenService(apiClient: APIClient(baseURL: baseURL, tokenService: TokenService(apiClient: APIClient(baseURL: baseURL, tokenService: EmptyTokenService()))))
    }()
    
    // Auth service for login/register/etc
    // Similar to having an auth service in React/Node.js that handles user authentication
    lazy var authService: AuthServiceProtocol = {
        AuthService(apiClient: apiClient, tokenService: tokenService)
    }()
    
    // Crypto service for token-related operations
    // Similar to having a service for specific API endpoints in React/Node.js
    lazy var cryptoService: TokenServiceProtocol = {
        TokenService(apiClient: apiClient)
    }()
    
    // Private constructor to enforce singleton pattern
    // Similar to how you might create a singleton in JavaScript:
    // class Container {
    //   private static instance: Container;
    //   private constructor() {}
    //   static getInstance() {
    //     if (!Container.instance) {
    //       Container.instance = new Container();
    //     }
    //     return Container.instance;
    //   }
    // }
    private init() {}
}

// Empty implementation to break circular dependency
// Similar to how you might use a mock or stub in JavaScript testing
private class EmptyTokenService: TokenServiceProtocol {
    // Token management methods
    func getValidToken() async throws -> String { 
        throw NetworkError.unauthorized 
    }
    
    func saveTokens(access: String, refresh: String, accessExpiration: Date, refreshExpiration: Date) throws {
        // Empty implementation
    }
    
    func clearTokens() throws {
        // Empty implementation
    }
    
    // Token data operations
    func getTokens() async throws -> [Token] {
        return []
    }
    
    func searchTokens(query: String) async throws -> [Token] {
        return []
    }
    
    func addToWatchlist(tokenId: String) async throws {
        // Empty implementation
    }
    
    func removeFromWatchlist(tokenId: String) async throws {
        // Empty implementation
    }
} 
