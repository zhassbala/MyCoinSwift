import Foundation
import SwiftUI
import SwiftData

@MainActor
class TokenViewModel: ObservableObject {
    @Published var tokens: [Token] = []
    @Published var watchlistTokens: [Token] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isOffline = false
    private let networkManager = NetworkManager.shared
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadPersistedData()
    }
    
    // MARK: - Persistence
    
    private func loadPersistedData() {
        let tokensDescriptor = FetchDescriptor<Token>()
        do {
            tokens = try modelContext.fetch(tokensDescriptor)
            watchlistTokens = tokens.filter { isInWatchlist($0) }
        } catch {
            print("Failed to load persisted data:", error)
        }
    }
    
    private func saveToken(_ token: Token) {
        // Check if token already exists
        if let existingToken = tokens.first(where: { $0.cryptocompareId == token.cryptocompareId }) {
            // Update existing token
            existingToken.codrepoPerc = token.codrepoPerc
            existingToken.fbPerc = token.fbPerc
            existingToken.redditPerc = token.redditPerc
            existingToken.twitterPerc = token.twitterPerc
            existingToken.totalPerc = token.totalPerc
            existingToken.bullish = token.bullish
            existingToken.neutral = token.neutral
            existingToken.bearish = token.bearish
            existingToken.imageUrl = token.imageUrl
            existingToken.fullname = token.fullname
            existingToken.symbol = token.symbol
            existingToken.coinname = token.coinname
            
            // Update relationships if they exist
            if let codrepo = token.codrepo {
                existingToken.codrepo = codrepo
            }
            if let facebook = token.facebook {
                existingToken.facebook = facebook
            }
            if let reddit = token.reddit {
                existingToken.reddit = reddit
            }
            if let twitter = token.twitter {
                existingToken.twitter = twitter
            }
        } else {
            // Insert new token
            modelContext.insert(token)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save token:", error)
        }
    }
    
    private func deleteToken(_ token: Token) {
        modelContext.delete(token)
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete token:", error)
        }
    }
    
    // MARK: - Token Operations
    
    func fetchTokens() async {
        self.isLoading = true
        self.error = nil
        
        do {
            let newTokens = try await networkManager.fetchTokens()
            
            // Update persisted data
            for token in newTokens {
                saveToken(token)
            }
            
            // Remove tokens that no longer exist
            let newTokenIds = Set(newTokens.map { $0.cryptocompareId })
            tokens.filter { !newTokenIds.contains($0.cryptocompareId) }
                .forEach { deleteToken($0) }
            
            tokens = newTokens
            isOffline = false
            
        } catch NetworkError.unauthorized {
            self.error = "Please sign in to view tokens"
            loadPersistedData() // Use persisted data
            isOffline = true
        } catch NetworkError.serverError(let message) {
            self.error = message
            loadPersistedData() // Use persisted data
            isOffline = true
        } catch {
            self.error = "Failed to load tokens. Using cached data."
            loadPersistedData() // Use persisted data
            isOffline = true
        }
        
        self.isLoading = false
    }
    
    func fetchWatchlist() async {
        self.isLoading = true
        self.error = nil
        
        do {
            let newWatchlistTokens = try await networkManager.fetchWatchlist()
            
            // Update persisted data
            for token in newWatchlistTokens {
                saveToken(token)
            }
            
            watchlistTokens = newWatchlistTokens
            isOffline = false
            
        } catch NetworkError.unauthorized {
            self.error = "Please sign in to view your watchlist"
            // Keep using existing watchlist data
            isOffline = true
        } catch NetworkError.serverError(let message) {
            self.error = message
            // Keep using existing watchlist data
            isOffline = true
        } catch {
            self.error = "Failed to load watchlist. Using cached data."
            // Keep using existing watchlist data
            isOffline = true
        }
        
        self.isLoading = false
    }
    
    func isInWatchlist(_ token: Token) -> Bool {
        return watchlistTokens.contains { $0.cryptocompareId == token.cryptocompareId }
    }
    
    func toggleWatchlist(for token: Token) async {
        self.isLoading = true
        self.error = nil
        
        let wasInWatchlist = isInWatchlist(token)
        
        // Optimistically update UI
        if wasInWatchlist {
            watchlistTokens.removeAll { $0.cryptocompareId == token.cryptocompareId }
        } else {
            watchlistTokens.append(token)
        }
        
        do {
            if wasInWatchlist {
                try await networkManager.removeFromWatchlist(tokenId: token.cryptocompareId)
            } else {
                try await networkManager.addToWatchlist(tokenId: token.cryptocompareId)
                saveToken(token)
            }
            isOffline = false
            
        } catch {
            // Revert optimistic update on error
            if wasInWatchlist {
                watchlistTokens.append(token)
            } else {
                watchlistTokens.removeAll { $0.cryptocompareId == token.cryptocompareId }
            }
            
            if let networkError = error as? NetworkError {
                switch networkError {
                case .unauthorized:
                    self.error = "Please sign in to manage your watchlist"
                case .serverError(let message):
                    self.error = message
                default:
                    self.error = "Failed to update watchlist. Please try again."
                }
            } else {
                self.error = "Failed to update watchlist. Please try again."
            }
            isOffline = true
        }
        
        self.isLoading = false
    }
    
    func fetchTokenDetails(tokenId: String) async -> Token? {
        self.isLoading = true
        self.error = nil
        
        // First try to get from persisted data
        if let existingToken = tokens.first(where: { $0.cryptocompareId == tokenId }),
           existingToken.codrepo != nil || existingToken.facebook != nil || existingToken.reddit != nil || existingToken.twitter != nil {
            self.isLoading = false
            return existingToken
        }
        
        do {
            let token = try await networkManager.fetchTokenDetails(tokenId: tokenId)
            saveToken(token)
            isOffline = false
            isLoading = false
            return token
            
        } catch NetworkError.unauthorized {
            self.error = "Please sign in to view token details"
            isOffline = true
        } catch NetworkError.serverError(let message) {
            self.error = message
            isOffline = true
        } catch {
            self.error = "Failed to load token details. Using cached data."
            isOffline = true
        }
        
        // Return persisted token if available
        let persistedToken = tokens.first { $0.cryptocompareId == tokenId }
        self.isLoading = false
        return persistedToken
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
