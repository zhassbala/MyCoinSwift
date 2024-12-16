import Foundation
import Security

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case serverError(String)
    case keychainError
}

// Response models for authentication
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

struct RegisterReponse: Codable {
    let name: String
    let email: String
    let profilePic: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case email
        case profilePic = "profile_pic"
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: UserResponse
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct RegisterRequest: Codable {
    let name: String
    let email: String
    let password: String
}

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://127.0.0.1:8000/api"
    private var accessToken: String? {
        didSet {
            if let token = accessToken {
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
        // Try to load tokens from keychain on initialization
        accessToken = loadTokenFromKeychain(forKey: "accessToken")
        refreshToken = loadTokenFromKeychain(forKey: "refreshToken")
    }
    
    // MARK: - Token Management
    
    private func saveTokenToKeychain(_ token: String, forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: token.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // First try to delete any existing token
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
        accessToken = nil
        refreshToken = nil
    }
    
    // MARK: - Authentication Endpoints
    
    func login(username: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/login/")!
        let loginRequest = LoginRequest(username: username, password: password)
        let response: AuthResponse = try await performRequest(url: url, method: "POST", body: loginRequest)
        setTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        return response
    }
    
    func register(name: String, email: String, password: String) async throws -> RegisterReponse {
        let url = URL(string: "\(baseURL)/auth/register")!
        let request = RegisterRequest(name: name, email: email, password: password)
        let response: RegisterReponse = try await performRequest(url: url, method: "POST", body: request)
        return response
    }
    
    func logout() async throws {
        guard let token = accessToken else { return }
        let url = URL(string: "\(baseURL)/auth/logout/")!
        let body = ["token": token]
        try await performRequestWithoutResponse(url: url, method: "POST", body: body)
        clearTokens()
    }
    
    // MARK: - Token Endpoints
    
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
        
        return try await performRequest(url: urlComponents.url!, method: "GET")
    }
    
    func fetchTokenSummary(tokenId: String) async throws -> Token {
        let url = URL(string: "\(baseURL)/token/\(tokenId)/summary")!
        return try await performRequest(url: url, method: "GET")
    }
    
    func fetchTokenDetails(tokenId: String) async throws -> Token {
        let url = URL(string: "\(baseURL)/token/\(tokenId)/full")!
        return try await performRequest(url: url, method: "GET")
    }
    
    // MARK: - Watchlist Endpoints
    
    func fetchWatchlist() async throws -> [Token] {
        let url = URL(string: "\(baseURL)/watchlist/")!
        return try await performRequest(url: url, method: "GET")
    }
    
    func addToWatchlist(tokenId: String) async throws {
        let url = URL(string: "\(baseURL)/watchlist/")!
        let body = ["token": tokenId]
        try await performRequestWithoutResponse(url: url, method: "POST", body: body)
    }
    
    func removeFromWatchlist(tokenId: String) async throws {
        let url = URL(string: "\(baseURL)/watchlist/\(tokenId)/")!
        try await performRequestWithoutResponse(url: url, method: "DELETE")
    }
    
    // MARK: - Helper Methods
    
    private func performRequest<T: Codable>(url: URL, method: String, body: Codable? = nil) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let accessToken = accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(body)
        }
        
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
            throw NetworkError.unauthorized
        default:
            // print full error message 
            print("Error:", String(data: data, encoding: .utf8) ?? "No data")
            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorResponse.values.first {
                throw NetworkError.serverError(errorMessage)
            }
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
    
    private func performRequestWithoutResponse(url: URL, method: String, body: [String: Any]? = nil) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let accessToken = accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
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
} 
