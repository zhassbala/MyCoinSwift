import SwiftUI

struct AuthenticationContainerView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case .notAuthenticated:
                LoginView(viewModel: viewModel)
            case .authenticated:
                ContentView()
                    .environmentObject(viewModel)
            case .error:
                LoginView(viewModel: viewModel)
            }
        }
    }
} 