import Foundation
import SwiftData

@Model
final class User {
    var id: String
    var email: String
    var authToken: String?
    var watchlist: [Token]
    
    init(id: String, email: String, authToken: String? = nil) {
        self.id = id
        self.email = email
        self.authToken = authToken
        self.watchlist = []
    }
} 