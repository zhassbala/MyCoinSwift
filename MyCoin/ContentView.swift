//
//  ContentView.swift
//  MyCoin
//
//  Created by Rassul Bessimbekov on 11.12.2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(0)
            
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            WatchlistView()
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
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    WatchlistSection()
                    MarketSentimentSection()
                    NewsletterSection()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct ExploreView: View {
    @Query private var tokens: [Token]
    @State private var searchText = ""
    
    var filteredTokens: [Token] {
        if searchText.isEmpty {
            return tokens
        }
        return tokens.filter { token in
            token.cryptocompareCoinname.localizedCaseInsensitiveContains(searchText) ||
            token.cryptocompareSymbol.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List(filteredTokens, id: \.cryptocompareId) { token in
                TokenRow(token: token)
            }
            .searchable(text: $searchText, prompt: "Search tokens")
            .navigationTitle("Explore")
        }
    }
}

struct WatchlistView: View {
    @Query(filter: #Predicate<Token> { token in
        token.isInWatchlist
    }) private var watchlistTokens: [Token]
    
    var body: some View {
        NavigationView {
            List {
                if watchlistTokens.isEmpty {
                    ContentUnavailableView(
                        "No Tokens in Watchlist",
                        systemImage: "star.slash",
                        description: Text("Add tokens from the Explore tab to track them here")
                    )
                } else {
                    ForEach(watchlistTokens, id: \.cryptocompareId) { token in
                        TokenRow(token: token)
                    }
                }
            }
            .navigationTitle("Watchlist")
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
                        authViewModel.signOut()
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
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(token.cryptocompareCoinname)
                    .font(.headline)
                Text(token.cryptocompareSymbol)
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
            
            Button {
                withAnimation {
                    token.isInWatchlist.toggle()
                    // TODO: Sync with backend
                }
            } label: {
                Image(systemName: token.isInWatchlist ? "star.fill" : "star")
                    .foregroundColor(token.isInWatchlist ? .yellow : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
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
    ContentView()
        .modelContainer(for: Token.self, inMemory: true)
}
