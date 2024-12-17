import Foundation
import Combine

// Similar to a React component's state management using hooks or Redux
// @MainActor ensures all UI updates happen on the main thread (like React's useEffect)
@MainActor
class TokenViewModel: ObservableObject {
    // Published properties are like React's useState hooks
    // When these change, the UI automatically updates (like React's state updates)
    @Published var tokens: [Token] = []          // Like useState<Token[]>([])
    @Published var watchlistTokens: [Token] = [] // Like useState<Token[]>([])
    @Published var isLoading = false            // Like useState<boolean>(false)
    @Published var error: String?               // Like useState<string | null>(null)
    
    // Dependency injection of the service, similar to useContext or props in React
    private let tokenService: TokenServiceProtocol
    
    // Constructor, similar to useEffect(() => {}, []) for initial data loading
    init(tokenService: TokenServiceProtocol = DependencyContainer.shared.tokenService) {
        self.tokenService = tokenService
        Task {
            await loadTokens()
        }
    }
    
    // Load tokens from API
    // Similar to:
    // const loadTokens = async () => {
    //   setIsLoading(true)
    //   try {
    //     const data = await tokenService.getTokens()
    //     setTokens(data)
    //     setWatchlistTokens(data.filter(t => t.isInWatchlist))
    //   } catch (error) {
    //     setError(error.message)
    //   } finally {
    //     setIsLoading(false)
    //   }
    // }
    func loadTokens() async {
        isLoading = true
        error = nil
        
        do {
            tokens = try await tokenService.getTokens()
            watchlistTokens = tokens.filter { $0.isInWatchlist }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // Toggle watchlist status
    // Similar to:
    // const toggleWatchlist = async (token: Token) => {
    //   try {
    //     if (token.isInWatchlist) {
    //       await tokenService.removeFromWatchlist(token.id)
    //     } else {
    //       await tokenService.addToWatchlist(token.id)
    //     }
    //     await loadTokens()
    //   } catch (error) {
    //     setError(error.message)
    //   }
    // }
    func toggleWatchlist(token: Token) async {
        do {
            if token.isInWatchlist {
                try await tokenService.removeFromWatchlist(tokenId: token.id)
            } else {
                try await tokenService.addToWatchlist(tokenId: token.id)
            }
            await loadTokens()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // Search tokens with debounce
    // Similar to:
    // const searchTokens = async (query: string) => {
    //   if (!query) {
    //     await loadTokens()
    //     return
    //   }
    //   setIsLoading(true)
    //   try {
    //     const data = await tokenService.searchTokens(query)
    //     setTokens(data)
    //     setWatchlistTokens(data.filter(t => t.isInWatchlist))
    //   } catch (error) {
    //     setError(error.message)
    //   } finally {
    //     setIsLoading(false)
    //   }
    // }
    func searchTokens(query: String) async {
        guard !query.isEmpty else {
            await loadTokens()
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            tokens = try await tokenService.searchTokens(query: query)
            watchlistTokens = tokens.filter { $0.isInWatchlist }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
} 