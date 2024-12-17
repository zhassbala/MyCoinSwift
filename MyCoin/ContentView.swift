//
//  ContentView.swift
//  MyCoin
//
//  Created by Rassul Bessimbekov on 11.12.2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some View {
        Group {
            if case .authenticated = authViewModel.state {
                MainTabView()
                    .environmentObject(authViewModel)
                    .environment(\.modelContext, modelContext)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
        .onAppear {
            authViewModel.setModelContext(modelContext)
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: TokenViewModel(modelContext: modelContext))
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(0)
            
            ExploreView(viewModel: TokenViewModel(modelContext: modelContext))
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            WatchlistView(viewModel: TokenViewModel(modelContext: modelContext))
                .tabItem {
                    Label("Watchlist", systemImage: "star.fill")
                }
                .tag(2)
            
            ProfileView()
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
    }
}

struct DashboardView: View {
    @ObservedObject var viewModel: TokenViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    WatchlistSection(viewModel: viewModel)
                    MarketSentimentSection(viewModel: viewModel)
                    NewsletterSection()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                Task {
                    await viewModel.fetchTokens()
                    await viewModel.fetchWatchlist()
                }
            }
        }
    }
}

struct ExploreView: View {
    @ObservedObject var viewModel: TokenViewModel
    @State private var searchText = ""
    @State private var selectedToken: Token?
    @State private var showingTokenDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    VStack {
                        Text(error)
                            .foregroundColor(.red)
                        Button("Try Again") {
                            Task {
                                await viewModel.fetchTokens()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    List {
                        ForEach(viewModel.filterTokens(by: searchText), id: \.cryptocompareId) { token in
                            TokenRow(token: token, onWatchlistToggle: {
                                Task {
                                    await viewModel.toggleWatchlist(for: token)
                                }
                            }, viewModel: viewModel)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedToken = token
                                showingTokenDetail = true
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search tokens")
                    .refreshable {
                        await viewModel.fetchTokens()
                    }
                }
            }
            .navigationTitle("Explore")
            .sheet(isPresented: $showingTokenDetail) {
                if let token = selectedToken {
                    TokenDetailView(token: token, viewModel: viewModel)
                }
            }
        }
        .task {
            await viewModel.fetchTokens()
        }
    }
}

struct WatchlistView: View {
    @ObservedObject var viewModel: TokenViewModel
    @State private var selectedToken: Token?
    @State private var showingTokenDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    VStack {
                        Text(error)
                            .foregroundColor(.red)
                        Button("Try Again") {
                            Task {
                                await viewModel.fetchWatchlist()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    if viewModel.watchlistTokens.isEmpty {
                        ContentUnavailableView(
                            "No Tokens in Watchlist",
                            systemImage: "star.slash",
                            description: Text("Add tokens from the Explore tab to track them here")
                        )
                    } else {
                        List {
                            ForEach(viewModel.watchlistTokens, id: \.cryptocompareId) { token in
                                TokenRow(token: token, onWatchlistToggle: {
                                    Task {
                                        await viewModel.toggleWatchlist(for: token)
                                    }
                                }, viewModel: viewModel)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedToken = token
                                    showingTokenDetail = true
                                }
                            }
                        }
                        .refreshable {
                            await viewModel.fetchWatchlist()
                        }
                    }
                }
            }
            .navigationTitle("Watchlist")
            .sheet(isPresented: $showingTokenDetail) {
                if let token = selectedToken {
                    TokenDetailView(token: token, viewModel: viewModel)
                }
            }
        }
        .task {
            await viewModel.fetchWatchlist()
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @AppStorage("pushNotifications") private var pushNotificationsEnabled = true
    @AppStorage("newsletter") private var newsletterEnabled = true
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    if let user = authViewModel.currentUser {
                        Text(user.email)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Sign Out", role: .destructive) {
                        Task {
                            await authViewModel.signOut()
                        }
                    }
                }
                
                Section("Preferences") {
                    Toggle("Push Notifications", isOn: $pushNotificationsEnabled)
                    Toggle("Newsletter", isOn: $newsletterEnabled)
                }
                
                Section("About") {
                    NavigationLink("How Crypto Works") {
                        CryptoEducationView()
                    }
                    
                    NavigationLink("Terms of Service") {
                        Text("Terms of Service content")
                    }
                    
                    NavigationLink("Privacy Policy") {
                        Text("Privacy Policy content")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct TokenRow: View {
    let token: Token
    let onWatchlistToggle: () -> Void
    @ObservedObject var viewModel: TokenViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(token.coinname)
                    .font(.headline)
                Text(token.symbol)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(token.totalPerc, specifier: "%.2f")%")
                    .foregroundColor(token.totalPerc >= 0 ? .green : .red)
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.green)
                    Text("\(token.bullish)")
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.red)
                    Text("\(token.bearish)")
                }
                .font(.caption)
            }
            
            Button(action: onWatchlistToggle) {
                Image(systemName: viewModel.isInWatchlist(token) ? "star.fill" : "star")
                    .foregroundColor(viewModel.isInWatchlist(token) ? .yellow : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}

struct TokenDetailView: View {
    let token: Token
    @ObservedObject var viewModel: TokenViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var detailedToken: Token?
    @State private var selectedTab = 0
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Section
                    HStack {
                        VStack(alignment: .leading) {
                            Text(token.coinname)
                                .font(.title)
                                .bold()
                            Text(token.symbol)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(token.totalPerc, specifier: "%.2f")%")
                            .font(.title2)
                            .bold()
                            .foregroundColor(token.totalPerc >= 0 ? .green : .red)
                    }
                    
                    AsyncImage(url: URL(string: token.imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                    } placeholder: {
                        ProgressView()
                    }
                    
                    Divider()
                    
                    // Market Sentiment Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Market Sentiment")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("Bullish")
                                    .foregroundColor(.green)
                                Text("\(token.bullish)")
                                    .font(.title3)
                                    .bold()
                            }
                            
                            VStack {
                                Text("Neutral")
                                    .foregroundColor(.gray)
                                Text("\(token.neutral)")
                                    .font(.title3)
                                    .bold()
                            }
                            
                            VStack {
                                Text("Bearish")
                                    .foregroundColor(.red)
                                Text("\(token.bearish)")
                                    .font(.title3)
                                    .bold()
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // Detailed Data Tabs
                    VStack(alignment: .leading, spacing: 0) {
                        Picker("Data Source", selection: $selectedTab) {
                            Text("Code").tag(0)
                            Text("Social").tag(1)
                            Text("Community").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.bottom)
                        
                        if isLoading {
                            VStack {
                                ProgressView()
                                Text("Loading details...")
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                        } else if let error = viewModel.error {
                            VStack(spacing: 10) {
                                Text(error)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                Button("Try Again") {
                                    Task {
                                        isLoading = true
                                        detailedToken = await viewModel.fetchTokenDetails(tokenId: token.cryptocompareId)
                                        isLoading = false
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                        } else {
                            TabView(selection: $selectedTab) {
                                // Code Repository Tab
                                VStack(alignment: .leading, spacing: 10) {
                                    if let codrepo = detailedToken?.codrepo {
                                        DetailRow(label: "Stars", value: "\(codrepo.stars)")
                                        DetailRow(label: "Forks", value: "\(codrepo.forks)")
                                        DetailRow(label: "Contributors", value: "\(codrepo.contributors)")
                                        DetailRow(label: "Closed Issues", value: "\(codrepo.closedTotalIssues)")
                                        DetailRow(label: "Subscribers", value: "\(codrepo.subscribers)")
                                    } else {
                                        Text("No repository data available")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .tag(0)
                                
                                // Social Media Tab
                                VStack(alignment: .leading, spacing: 20) {
                                    if let twitter = detailedToken?.twitter {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text("Twitter")
                                                .font(.headline)
                                                .padding(.top, 50)
                                            DetailRow(label: "Followers", value: "\(twitter.followers)")
                                            DetailRow(label: "Following", value: "\(twitter.following)")
                                            DetailRow(label: "Lists", value: "\(twitter.lists)")
                                            DetailRow(label: "Tweets", value: "\(twitter.statuses)")
                                        }
                                    }
                                    
                                    if let facebook = detailedToken?.facebook {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text("Facebook")
                                                .font(.headline)
                                            DetailRow(label: "Likes", value: "\(facebook.likes)")
                                            DetailRow(label: "Talking About", value: "\(facebook.talkingAbout)")
                                        }
                                    }
                                    
                                    if detailedToken?.twitter == nil && detailedToken?.facebook == nil {
                                        Text("No social media data available")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .tag(1)
                                
                                // Community Tab
                                VStack(alignment: .leading, spacing: 10) {
                                    if let reddit = detailedToken?.reddit {
                                        Text("Reddit")
                                            .font(.headline)
                                        DetailRow(label: "Subscribers", value: "\(reddit.subscribers)")
                                        DetailRow(label: "Active Users", value: "\(reddit.activeUsers)")
                                        DetailRow(label: "Posts per Day", value: String(format: "%.2f", reddit.postsPerDay))
                                        DetailRow(label: "Comments per Day", value: String(format: "%.2f", reddit.commentsPerDay))
                                    } else {
                                        Text("No community data available")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .tag(2)
                            }
                            .frame(height: 250)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .task {
            // Start loading detailed data immediately
            Task {
                isLoading = true
                detailedToken = await viewModel.fetchTokenDetails(tokenId: token.cryptocompareId)
                isLoading = false
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

struct SentimentRow: View {
    let label: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(value, specifier: "%.2f")%")
                .foregroundColor(value >= 50 ? .green : .red)
        }
    }
}

struct CryptoEducationView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Understanding Cryptocurrency")
                    .font(.title)
                    .bold()
                
                Group {
                    Text("What is Cryptocurrency?")
                        .font(.headline)
                    Text("Cryptocurrency is a digital or virtual form of currency that uses cryptography for security. Unlike traditional currencies, cryptocurrencies are typically decentralized systems based on blockchain technology.")
                    
                    Text("How Does Blockchain Work?")
                        .font(.headline)
                    Text("Blockchain is a distributed ledger that records all transactions across a network of computers. Each block contains a list of transactions and is linked to the previous block, forming a chain of information that cannot be altered.")
                    
                    Text("Key Terms")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("• Blockchain: A decentralized, distributed ledger")
                        Text("• Mining: The process of validating transactions")
                        Text("• Wallet: Where you store your cryptocurrencies")
                        Text("• DeFi: Decentralized Finance applications")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Crypto Education")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Token.self, AuthState.self, configurations: config)
    
    ContentView()
        .modelContainer(container)
}
