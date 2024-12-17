import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case serverError(String)
    case keychainError
    case tokenRefreshFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from the server"
        case .decodingError:
            return "Failed to decode the response"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let message):
            return "Server error: \(message)"
        case .keychainError:
            return "Failed to access keychain"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
        }
    }
} 