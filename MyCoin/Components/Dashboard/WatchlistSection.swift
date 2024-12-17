import SwiftUI

// Watchlist section component
// Similar to a React functional component
struct WatchlistSection: View {
    @EnvironmentObject var tokenViewModel: TokenViewModel
    @State private var selectedToken: Token?
    @State private var showingTokenDetail = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Your Watchlist")
                .font(.title2)
                .bold()
            
            if tokenViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let error = tokenViewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if tokenViewModel.watchlistTokens.isEmpty {
                Text("Add tokens to your watchlist to track them here")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(tokenViewModel.watchlistTokens) { token in
                            WatchlistCard(token: token)
                                .onTapGesture {
                                    selectedToken = token
                                    showingTokenDetail = true
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showingTokenDetail) {
            if let token = selectedToken {
                TokenDetailView(token: token)
            }
        }
    }
}

// Card component for watchlist items
// Similar to a reusable React component
struct WatchlistCard: View {
    let token: Token
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with symbol and watchlist button
            HStack {
                Text(token.symbol)
                    .font(.headline)
                
                Spacer()
                
                WatchlistButton(token: token)
            }
            
            // Price info
            Text("$\(token.price, specifier: "%.2f")")
                .font(.title3)
                .bold()
            
            // Change percentage
            Text("\(token.change24h, specifier: "%.2f")%")
                .foregroundColor(token.change24h >= 0 ? .green : .red)
                .font(.subheadline)
            
            // Market cap
            Text("MCap: $\(token.marketCap / 1_000_000, specifier: "%.1f")M")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 160)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// Reusable watchlist button
// Similar to a React button component
struct WatchlistButton: View {
    let token: Token
    @EnvironmentObject var tokenViewModel: TokenViewModel
    
    var body: some View {
        Button {
            Task {
                await tokenViewModel.toggleWatchlist(token: token)
            }
        } label: {
            Image(systemName: token.isInWatchlist ? "star.fill" : "star")
                .foregroundColor(token.isInWatchlist ? .yellow : .gray)
        }
    }
} 