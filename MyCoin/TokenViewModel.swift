import Foundation
import SwiftUI
import SwiftData

@MainActor
class TokenViewModel: ObservableObject {
    @Published var tokens: [Token] = []
    @Published var watchlistTokens: [Token] = []
    @Published var isLoading = false
    @Published var error: String?
    private let networkManager = NetworkManager.shared
    
    // MARK: - Token Operations
    
    func fetchTokens() async {
        self.isLoading = true
        self.error = nil
        
        do {
            tokens = try await networkManager.fetchTokens()
        } catch NetworkError.unauthorized {
            self.error = "Please sign in to view tokens"
        } catch NetworkError.serverError(let message) {
            self.error = message
        } catch {
            self.error = "Failed to load tokens. Please try again."
        }
        
        self.isLoading = false
    }
    
    func fetchWatchlist() async {
        self.isLoading = true
        self.error = nil
        
        do {
            watchlistTokens = try await networkManager.fetchWatchlist()
        } catch NetworkError.unauthorized {
            self.error = "Please sign in to view your watchlist"
        } catch NetworkError.serverError(let message) {
            self.error = message
        } catch {
            self.error = "Failed to load watchlist. Please try again."
        }
        
        self.isLoading = false
    }
    
    func isInWatchlist(_ token: Token) -> Bool {
        return watchlistTokens.contains { $0.cryptocompareId == token.cryptocompareId }
    }
    
    func toggleWatchlist(for token: Token) async {
        self.isLoading = true
        self.error = nil
        
        do {
            if isInWatchlist(token) {
                try await networkManager.removeFromWatchlist(tokenId: token.cryptocompareId)
                if let index = watchlistTokens.firstIndex(where: { $0.cryptocompareId == token.cryptocompareId }) {
                    watchlistTokens.remove(at: index)
                }
            } else {
                try await networkManager.addToWatchlist(tokenId: token.cryptocompareId)
                watchlistTokens.append(token)
            }
        } catch NetworkError.unauthorized {
            self.error = "Please sign in to manage your watchlist"
        } catch NetworkError.serverError(let message) {
            self.error = message
        } catch {
            self.error = "Failed to update watchlist. Please try again."
        }
        
        self.isLoading = false
    }
    
    func fetchTokenDetails(tokenId: String) async -> Token? {
        self.isLoading = true
        self.error = nil
        
        do {
            let token = try await networkManager.fetchTokenDetails(tokenId: tokenId)
            isLoading = false
            return token
        } catch NetworkError.unauthorized {
            self.error = "Please sign in to view token details"
        } catch NetworkError.serverError(let message) {
            self.error = message
        } catch {
            self.error = "Failed to load token details. Please try again."
        }
        
        self.isLoading = false
        return nil
    }
    
    // MARK: - Filtering and Sorting
    
    func filterTokens(by searchText: String) -> [Token] {
        if searchText.isEmpty {
            return tokens
        }
        return tokens.filter { token in
            token.coinname.localizedCaseInsensitiveContains(searchText) ||
            token.symbol.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func getBullishTokens() -> [Token] {
        return tokens.sorted { $0.bullish > $1.bullish }
    }
    
    func getBearishTokens() -> [Token] {
        return tokens.sorted { $0.bearish > $1.bearish }
    }
} 
