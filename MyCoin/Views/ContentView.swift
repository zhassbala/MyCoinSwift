import SwiftUI

// Main content view that handles the app's root navigation
// Similar to how you might use React Router for navigation
struct ContentView: View {
    // State management through view model, similar to React's useState and useContext
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var tokenViewModel = TokenViewModel()
    
    var body: some View {
        Group {
            switch authViewModel.state {
            case .authenticated:
                // Main tab view when user is logged in
                MainTabView()
                    .environmentObject(authViewModel)
                    .environmentObject(tokenViewModel)
            case .notAuthenticated, .error:
                // Login view when user is not authenticated
                LoginView(viewModel: authViewModel)
            case .idle, .loading:
                // Loading state
                ProgressView()
            }
        }
    }
}

// Main tab view for authenticated users
// Similar to React Router's nested routes or a tab navigation component
struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var tokenViewModel: TokenViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard tab
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(0)
            
            // Explore tab
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            // Profile tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
        }
    }
}

// Dashboard view showing token overview
struct DashboardView: View {
    @EnvironmentObject var tokenViewModel: TokenViewModel
    
    var body: some View {
        NavigationView {
            List {
                // Watchlist section
                Section(header: Text("Watchlist")) {
                    ForEach(tokenViewModel.watchlistTokens) { token in
                        TokenRowView(token: token)
                    }
                }
                
                // All tokens section
                Section(header: Text("All Tokens")) {
                    ForEach(tokenViewModel.tokens) { token in
                        TokenRowView(token: token)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await tokenViewModel.loadTokens()
            }
        }
        .task {
            await tokenViewModel.loadTokens()
        }
    }
}

// Explore view with search functionality
struct ExploreView: View {
    @EnvironmentObject var tokenViewModel: TokenViewModel
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List(tokenViewModel.tokens) { token in
                TokenRowView(token: token)
            }
            .navigationTitle("Explore")
            .searchable(text: $searchText)
            .onChange(of: searchText) { _, newValue in
                Task {
                    await tokenViewModel.searchTokens(query: newValue)
                }
            }
        }
    }
}

// Profile view
struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            List {
                if let user = authViewModel.currentUser {
                    Section(header: Text("Profile")) {
                        Text("Name: \(user.firstName) \(user.lastName)")
                        Text("Email: \(user.email)")
                    }
                }
                
                Section {
                    Button("Sign Out", role: .destructive) {
                        Task {
                            await authViewModel.logout()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

// Reusable token row view
struct TokenRowView: View {
    let token: Token
    @EnvironmentObject var tokenViewModel: TokenViewModel
    
    var body: some View {
        HStack {
            // Token info
            VStack(alignment: .leading) {
                Text(token.symbol)
                    .font(.headline)
                Text(token.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Price info
            VStack(alignment: .trailing) {
                Text("$\(token.price, specifier: "%.2f")")
                    .font(.headline)
                Text("\(token.change24h, specifier: "%.2f")%")
                    .font(.subheadline)
                    .foregroundColor(token.change24h >= 0 ? .green : .red)
            }
            
            // Watchlist button
            Button {
                Task {
                    await tokenViewModel.toggleWatchlist(token: token)
                }
            } label: {
                Image(systemName: token.isInWatchlist ? "star.fill" : "star")
                    .foregroundColor(token.isInWatchlist ? .yellow : .gray)
            }
        }
        .padding(.vertical, 4)
    }
} 