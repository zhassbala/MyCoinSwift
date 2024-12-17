import Foundation

// Similar to axios or fetch configuration in web development
// This protocol defines what our API client can do, like how you'd define TypeScript interfaces
protocol APIClientProtocol {
    // Generic request method, similar to axios.get<T>() in TypeScript
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    // Request without response data, like axios.post() without expecting data back
    func request(_ endpoint: APIEndpoint) async throws
}

// Similar to how you'd configure an API endpoint in React/Node.js
struct APIEndpoint {
    let path: String           // The URL path, like '/api/users'
    let method: HTTPMethod     // HTTP method (GET, POST, etc.)
    let body: Encodable?       // Request body, like axios payload
    let requiresAuth: Bool     // Whether to include auth token, like in axios interceptors
    
    init(path: String, method: HTTPMethod = .get, body: Encodable? = nil, requiresAuth: Bool = true) {
        self.path = path
        self.method = method
        self.body = body
        self.requiresAuth = requiresAuth
    }
}

// Similar to HTTP methods in REST APIs
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// Main API client, similar to creating an axios instance with baseURL and interceptors
class APIClient: APIClientProtocol {
    private let baseURL: String
    private let tokenService: TokenServiceProtocol
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    
    init(baseURL: String, tokenService: TokenServiceProtocol) {
        self.baseURL = baseURL
        self.tokenService = tokenService
        
        // Configure JSON decoder/encoder
        self.jsonDecoder = JSONDecoder()
        self.jsonEncoder = JSONEncoder()
    }
    
    // Generic request method with type T, similar to axios.request<T>()
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let request = try await createRequest(for: endpoint)
        
        // Print request details for debugging
        print("Request URL:", request.url?.absoluteString ?? "")
        print("Request Method:", request.httpMethod ?? "")
        print("Request Headers:", request.allHTTPHeaderFields ?? [:])
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Request Body:", bodyString)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Print response details for debugging
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status:", httpResponse.statusCode)
            print("Response Headers:", httpResponse.allHeaderFields)
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response Body:", responseString)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }
        
        // Handle response status, similar to axios response interceptors
        switch httpResponse.statusCode {
        case 200...299:
            do {
                // Parse JSON response, similar to response.json() in fetch
                return try jsonDecoder.decode(T.self, from: data)
            } catch {
                print("Decoding Error:", error)
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Failed to decode:", responseString)
                }
                throw NetworkError.decodingError
            }
        case 401:
            throw NetworkError.unauthorized
        default:
            if let errorString = String(data: data, encoding: .utf8) {
                throw NetworkError.serverError("Status code: \(httpResponse.statusCode), Error: \(errorString)")
            } else {
                throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
            }
        }
    }
    
    // Request without response data
    func request(_ endpoint: APIEndpoint) async throws {
        let request = try await createRequest(for: endpoint)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                throw NetworkError.serverError("Status code: \(httpResponse.statusCode), Error: \(errorString)")
            } else {
                throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
            }
        }
    }
    
    // Create URLRequest with proper headers and body, similar to axios config
    private func createRequest(for endpoint: APIEndpoint) async throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth header if needed, similar to axios interceptors adding Authorization header
        if endpoint.requiresAuth {
            let token = try await tokenService.getValidToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add request body if provided, similar to axios data parameter
        if let body = endpoint.body {
            request.httpBody = try jsonEncoder.encode(body)
        }
        
        return request
    }
} 