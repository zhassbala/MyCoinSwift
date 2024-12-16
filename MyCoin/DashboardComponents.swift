import SwiftUI
import SwiftData

struct WatchlistSection: View {
    @Query(filter: #Predicate<Token> { token in
        token.isInWatchlist
    }) private var watchlistTokens: [Token]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Your Watchlist")
                .font(.title2)
                .bold()
            
            if watchlistTokens.isEmpty {
                Text("Add tokens to your watchlist to track them here")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(watchlistTokens.prefix(5), id: \.cryptocompareId) { token in
                            WatchlistCard(token: token)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct WatchlistCard: View {
    let token: Token
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(token.cryptocompareSymbol)
                    .font(.headline)
                Spacer()
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
            
            Text(token.cryptocompareCoinname)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(token.totalPerc, specifier: "%.2f")%")
                .font(.title3)
                .foregroundColor(token.totalPerc >= 0 ? .green : .red)
        }
        .padding()
        .frame(width: 150, height: 120)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct MarketSentimentSection: View {
    @Query(filter: #Predicate<Token> { token in
        token.totalPerc >= 5
    }, sort: \Token.totalPerc, order: .reverse) private var bullishTokens: [Token]
    
    @Query(filter: #Predicate<Token> { token in
        token.totalPerc <= -5
    }, sort: \Token.totalPerc) private var bearishTokens: [Token]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Market Sentiment")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Most Bullish")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(bullishTokens.prefix(5), id: \.cryptocompareId) { token in
                            SentimentCard(token: token)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Most Bearish")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(bearishTokens.prefix(5), id: \.cryptocompareId) { token in
                            SentimentCard(token: token)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct SentimentCard: View {
    let token: Token
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(token.cryptocompareSymbol)
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.green)
                        Text("\(token.bullish)")
                    }
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.red)
                        Text("\(token.bearish)")
                    }
                }
                
                Spacer()
                
                Text("\(token.totalPerc, specifier: "%.1f")%")
                    .font(.title3)
                    .foregroundColor(token.totalPerc >= 0 ? .green : .red)
            }
        }
        .padding()
        .frame(width: 150, height: 100)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct NewsletterSection: View {
    @State private var email = ""
    @State private var isSubscribed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Newsletter")
                .font(.title2)
                .bold()
            
            Text("Stay updated with crypto trends and analysis")
                .foregroundColor(.secondary)
            
            if !isSubscribed {
                HStack {
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Subscribe") {
                        // Handle newsletter subscription
                        withAnimation {
                            isSubscribed = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("You're subscribed!")
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
} 