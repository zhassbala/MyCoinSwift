import Foundation
import Security

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case serverError(String)
    case keychainError
    case tokenRefreshFailed
}

struct UserResponse: Codable {
    let pk: Int
    let email: String
    let firstName: String
    let lastName: String
    
    enum CodingKeys: String, CodingKey {
        case pk
        case email
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: UserResponse
    let accessTokenExpiration: String
    let refreshTokenExpiration: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
        case accessTokenExpiration = "access_token_expiration"
        case refreshTokenExpiration = "refresh_token_expiration"
    }
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
}

struct TokenRefreshRequest: Codable {
    let refresh: String
}

struct TokenRefreshResponse: Codable {
    let access: String
}

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://127.0.0.1:8000/api"
    private var accessToken: String? {
        didSet {
            if let token = self.accessToken {
                saveTokenToKeychain(token, forKey: "accessToken")
            } else {
                deleteTokenFromKeychain(forKey: "accessToken")
            }
        }
    }
    private var refreshToken: String? {
        didSet {
            if let token = refreshToken {
                saveTokenToKeychain(token, forKey: "refreshToken")
            } else {
                deleteTokenFromKeychain(forKey: "refreshToken")
            }
        }
    }
    
    private init() {
        self.accessToken = loadTokenFromKeychain(forKey: "accessToken")
        self.refreshToken = loadTokenFromKeychain(forKey: "refreshToken")
    }
    
    // MARK: - Token Management
    
    private func saveTokenToKeychain(_ token: String, forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: token.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving token to Keychain: \(status)")
        }
    }
    
    func loadTokenFromKeychain(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data, let token = String(data: data, encoding: .utf8) {
            return token
        }
        return nil
    }
    
    private func deleteTokenFromKeychain(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    func setTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    func clearTokens() {
        self.accessToken = nil
        self.refreshToken = nil
    }
    
    // MARK: - Token Refresh
    
    private func refreshAccessToken() async throws {
        guard let refreshToken = self.refreshToken else {
            throw NetworkError.tokenRefreshFailed
        }
        
        let url = URL(string: "\(baseURL)/auth/token/refresh/")!
        let request = TokenRefreshRequest(refresh: refreshToken)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try? JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }
        
        if httpResponse.statusCode == 200 {
            let refreshResponse = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
            self.accessToken = refreshResponse.access
        } else {
            if httpResponse.statusCode == 401 {
                // If refresh token is invalid, clear tokens and force re-login
                clearTokens()
            }
            throw NetworkError.tokenRefreshFailed
        }
    }
    
    // MARK: - Authentication Endpoints
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/login/")!
        let loginRequest = LoginRequest(username: email, password: password)
        let response: AuthResponse = try await performRequest(url: url, method: "POST", body: loginRequest)
        setTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        return response
    }
    
    func register(username: String, email: String, password: String) async throws -> UserResponse {
        let url = URL(string: "\(baseURL)/auth/register")!
        let request = RegisterRequest(username: username, email: email, password: password)
        let response: AuthResponse = try await performRequest(url: url, method: "POST", body: request)
        return response.user
    }
    
    func logout() async throws {
        guard let refreshToken = refreshToken else { return }
        let url = URL(string: "\(baseURL)/auth/logout/")!
        let request = TokenRefreshRequest(refresh: refreshToken)
        try await performRequestWithoutResponse(url: url, method: "POST", body: request)
        clearTokens()
    }
    
    func verifyToken(_ token: String) async throws {
        let url = URL(string: "\(baseURL)/auth/token/verify/")!
        let request = ["token": token]
        try await performRequestWithoutResponse(url: url, method: "POST", body: request as [String: String])
    }
    
    // MARK: - Helper Methods
    
    private func performRequest<T: Codable, U: Codable>(url: URL, method: String, body: U? = nil) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let accessToken = self.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(body)
        }
        
        do {
            return try await sendRequest(request)
        } catch NetworkError.unauthorized {
            print("Unauthorized")
            // Try to refresh token and retry the request
            try await refreshAccessToken()
            if let accessToken = self.accessToken {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                return try await sendRequest(request)
            }
            throw NetworkError.unauthorized
        }
    }
    
    private func performRequestWithoutResponse<U: Codable>(url: URL, method: String, body: U? = nil) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let accessToken = accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(body)
        }
        
        do {
            try await sendRequestWithoutResponse(request)
        } catch NetworkError.unauthorized {
            // Try to refresh token and retry the request
            try await refreshAccessToken()
            if let accessToken = accessToken {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                try await sendRequestWithoutResponse(request)
            }
            throw NetworkError.unauthorized
        }
    }
    
    private func sendRequest<T: Codable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                print("Decoding error:", error)
                throw NetworkError.decodingError
            }
        case 401:
            // print full error message
            print("Error:", String(data: data, encoding: .utf8) ?? "No data")
            throw NetworkError.unauthorized
        default:
            // print full error message 
            print("Error:", String(data: data, encoding: .utf8) ?? "No data")
            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorResponse["error"] {
                throw NetworkError.serverError(errorMessage)
            }
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
    
    private func sendRequestWithoutResponse(_ request: URLRequest) async throws {
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Protected Endpoints
    
    func fetchTokens(minTotalPerc: Float? = nil, sentiment: String? = nil) async throws -> [Token] {
        var urlComponents = URLComponents(string: "\(baseURL)/tokens/")!
        var queryItems: [URLQueryItem] = []
        
        if let minTotalPerc = minTotalPerc {
            queryItems.append(URLQueryItem(name: "min_total_perc", value: String(minTotalPerc)))
        }
        
        if let sentiment = sentiment {
            queryItems.append(URLQueryItem(name: "sentiment", value: sentiment))
        }
        
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }
        
        return try await performRequest(url: urlComponents.url!, method: "GET", body: Optional<EmptyRequest>.none)
    }
    
    func fetchTokenSummary(tokenId: String) async throws -> Token {
        let url = URL(string: "\(baseURL)/token/\(tokenId)/summary")!
        return try await performRequest(url: url, method: "GET", body: Optional<EmptyRequest>.none)
    }
    
    func fetchTokenDetails(tokenId: String) async throws -> Token {
        let url = URL(string: "\(baseURL)/token/\(tokenId)/full")!
        return try await performRequest(url: url, method: "GET", body: Optional<EmptyRequest>.none)
    }
    
    func fetchWatchlist() async throws -> [Token] {
        let url = URL(string: "\(baseURL)/watchlist/")!
        return try await performRequest(url: url, method: "GET", body: Optional<EmptyRequest>.none)
    }
    
    func addToWatchlist(tokenId: String) async throws {
        let url = URL(string: "\(baseURL)/watchlist/")!
        let body = ["token": tokenId]
        try await performRequestWithoutResponse(url: url, method: "POST", body: body as [String: String])
    }
    
    func removeFromWatchlist(tokenId: String) async throws {
        let url = URL(string: "\(baseURL)/watchlist/\(tokenId)/")!
        try await performRequestWithoutResponse(url: url, method: "DELETE", body: Optional<EmptyRequest>.none)
    }
    
    // MARK: - Helper Types
    
    private struct EmptyRequest: Codable {} // Used for endpoints with no request body
} 
