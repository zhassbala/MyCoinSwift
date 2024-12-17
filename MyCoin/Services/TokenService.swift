import Foundation

// Similar to a service layer in React/Node.js that handles specific API endpoints
protocol TokenServiceProtocol {
    // Token management
    func getValidToken() async throws -> String
    func saveTokens(access: String, refresh: String, accessExpiration: Date, refreshExpiration: Date) throws
    func clearTokens() throws
    
    // Token data operations
    func getTokens() async throws -> [Token]
    func searchTokens(query: String) async throws -> [Token]
    func addToWatchlist(tokenId: String) async throws
    func removeFromWatchlist(tokenId: String) async throws
}

// Implementation of the token service
class TokenService: TokenServiceProtocol {
    private let apiClient: APIClientProtocol
    private let keychainService = "com.mycoin.tokens"
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let accessExpirationKey = "accessExpiration"
    private let refreshExpirationKey = "refreshExpiration"
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    // Token management methods
    func getValidToken() async throws -> String {
        guard let accessToken = try getAccessToken(),
              let accessExpiration = try getAccessExpiration() else {
            throw NetworkError.unauthorized
        }
        
        if Date() >= accessExpiration {
            return try await refreshAccessToken()
        }
        
        return accessToken
    }
    
    func saveTokens(access: String, refresh: String, accessExpiration: Date, refreshExpiration: Date) throws {
        try saveToKeychain(key: accessTokenKey, value: access)
        try saveToKeychain(key: refreshTokenKey, value: refresh)
        try saveToKeychain(key: accessExpirationKey, value: accessExpiration.ISO8601Format())
        try saveToKeychain(key: refreshExpirationKey, value: refreshExpiration.ISO8601Format())
    }
    
    func clearTokens() throws {
        try deleteFromKeychain(key: accessTokenKey)
        try deleteFromKeychain(key: refreshTokenKey)
        try deleteFromKeychain(key: accessExpirationKey)
        try deleteFromKeychain(key: refreshExpirationKey)
    }
    
    // Token data methods
    func getTokens() async throws -> [Token] {
        let endpoint = APIEndpoint(path: "/tokens")
        let response: [TokenResponse] = try await apiClient.request(endpoint)
        return response.map(mapTokenResponse)
    }
    
    func searchTokens(query: String) async throws -> [Token] {
        let endpoint = APIEndpoint(path: "/tokens/search", method: .get, body: ["query": query])
        let response: [TokenResponse] = try await apiClient.request(endpoint)
        return response.map(mapTokenResponse)
    }
    
    func addToWatchlist(tokenId: String) async throws {
        let endpoint = APIEndpoint(path: "/watchlist/add/\(tokenId)", method: .post)
        try await apiClient.request(endpoint)
    }
    
    func removeFromWatchlist(tokenId: String) async throws {
        let endpoint = APIEndpoint(path: "/watchlist/remove/\(tokenId)", method: .delete)
        try await apiClient.request(endpoint)
    }
    
    // Private helper methods
    private func mapTokenResponse(_ tokenResponse: TokenResponse) -> Token {
        Token(
            id: tokenResponse.id,
            symbol: tokenResponse.symbol,
            name: tokenResponse.name,
            fullName: tokenResponse.fullName,
            imageUrl: tokenResponse.imageUrl,
            price: tokenResponse.price,
            marketCap: tokenResponse.marketCap,
            volume24h: tokenResponse.volume24h,
            change24h: tokenResponse.change24h,
            isInWatchlist: false,
            twitterFollowers: tokenResponse.socialMetrics.twitterFollowers,
            redditSubscribers: tokenResponse.socialMetrics.redditSubscribers,
            githubStars: tokenResponse.socialMetrics.githubStars,
            bullishPercentage: tokenResponse.sentimentMetrics.bullishPercentage,
            bearishPercentage: tokenResponse.sentimentMetrics.bearishPercentage,
            neutralPercentage: tokenResponse.sentimentMetrics.neutralPercentage
        )
    }
    
    private func refreshAccessToken() async throws -> String {
        guard let refreshToken = try getRefreshToken(),
              let refreshExpiration = try getRefreshExpiration() else {
            throw NetworkError.unauthorized
        }
        
        if Date() >= refreshExpiration {
            throw NetworkError.unauthorized
        }
        
        let endpoint = APIEndpoint(
            path: "/auth/refresh",
            method: .post,
            body: ["refresh_token": refreshToken],
            requiresAuth: false
        )
        
        let response: AuthResponse = try await apiClient.request(endpoint)
        try saveTokens(
            access: response.accessToken,
            refresh: response.refreshToken,
            accessExpiration: ISO8601DateFormatter().date(from: response.accessTokenExpiration) ?? Date(),
            refreshExpiration: ISO8601DateFormatter().date(from: response.refreshTokenExpiration) ?? Date()
        )
        
        return response.accessToken
    }
    
    private func getAccessToken() throws -> String? {
        try getFromKeychain(key: accessTokenKey)
    }
    
    private func getRefreshToken() throws -> String? {
        try getFromKeychain(key: refreshTokenKey)
    }
    
    private func getAccessExpiration() throws -> Date? {
        guard let dateString = try getFromKeychain(key: accessExpirationKey) else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }
    
    private func getRefreshExpiration() throws -> Date? {
        guard let dateString = try getFromKeychain(key: refreshExpirationKey) else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }
    
    private func saveToKeychain(key: String, value: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: value.data(using: .utf8)!
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NetworkError.keychainError
        }
    }
    
    private func getFromKeychain(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func deleteFromKeychain(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw NetworkError.keychainError
        }
    }
} 