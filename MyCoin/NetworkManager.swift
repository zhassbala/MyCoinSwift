import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case serverError(String)
}

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://127.0.0.1:8000/api/"
    private var authToken: String?
    
    private init() {}
    
    func setAuthToken(_ token: String) {
        self.authToken = token
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
    
    private func performRequest<T: Decodable>(url: URL, method: String, body: [String: Any]? = nil) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
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
                throw NetworkError.decodingError
            }
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
    
    private func performRequestWithoutResponse(url: URL, method: String, body: [String: Any]? = nil) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
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
