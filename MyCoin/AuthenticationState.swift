import Foundation
import SwiftData

@Model
final class AuthState {
    var isAuthenticated: Bool
    var userId: String?
    var userEmail: String?
    
    init(isAuthenticated: Bool = false, userId: String? = nil, userEmail: String? = nil) {
        self.isAuthenticated = isAuthenticated
        self.userId = userId
        self.userEmail = userEmail
    }
} 