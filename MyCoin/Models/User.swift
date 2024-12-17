import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: Int
    let email: String
    let firstName: String
    let lastName: String
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "pk"
        case email
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

// Response Models
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