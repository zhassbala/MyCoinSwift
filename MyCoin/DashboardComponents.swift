import SwiftUI
import SwiftData

struct WatchlistSection: View {
    @ObservedObject var viewModel: TokenViewModel
    @State private var selectedToken: Token?
    @State private var showingTokenDetail = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Your Watchlist")
                .font(.title2)
                .bold()
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if viewModel.watchlistTokens.isEmpty {
                Text("Add tokens to your watchlist to track them here")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(viewModel.watchlistTokens.prefix(5), id: \.cryptocompareId) { token in
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
                TokenDetailView(token: token, viewModel: viewModel)
            }
        }
        .task {
            await viewModel.fetchWatchlist()
        }
    }
}

struct WatchlistCard: View {
    let token: Token
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(token.symbol)
                    .font(.headline)
                Spacer()
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
            
            Text(token.coinname)
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
        .padding(.vertical)
    }
}

struct MarketSentimentSection: View {
    @ObservedObject var viewModel: TokenViewModel
    @State private var selectedToken: Token?
    @State private var showingTokenDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Market Sentiment")
                .font(.title2)
                .bold()
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Most Bullish")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(viewModel.getBullishTokens().prefix(5), id: \.cryptocompareId) { token in
                                SentimentCard(token: token)
                                    .onTapGesture {
                                        selectedToken = token
                                        showingTokenDetail = true
                                    }
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
                            ForEach(viewModel.getBearishTokens().prefix(5), id: \.cryptocompareId) { token in
                                SentimentCard(token: token)
                                    .onTapGesture {
                                        self.selectedToken = token
                                        self.showingTokenDetail = true
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTokenDetail) {
            if let token = selectedToken {
                TokenDetailView(token: token, viewModel: viewModel)
            }
        }
        .task {
            await viewModel.fetchTokens()
        }
    }
}

struct SentimentCard: View {
    let token: Token
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(token.symbol)
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
        .padding(.vertical)
    }
}

struct NewsletterSection: View {
    @State private var email = ""
    @State private var isSubscribed = false
    @State private var error: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Newsletter")
                .font(.title2)
                .bold()
            
            Text("Stay updated with crypto trends and analysis")
                .foregroundColor(.secondary)
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if !isSubscribed {
                HStack {
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Button(action: handleSubscribe) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Subscribe")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
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
    
    private func handleSubscribe() {
        guard isValidEmail(email) else {
            error = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        error = nil
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            isSubscribed = true
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
} 
