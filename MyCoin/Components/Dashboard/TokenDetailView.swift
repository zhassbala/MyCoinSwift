import SwiftUI

// Token detail view component
// Similar to a React modal or detail page component
struct TokenDetailView: View {
    let token: Token
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tokenViewModel: TokenViewModel
    
    // Number formatter for price and percentages
    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    private let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header section
                    HStack {
                        VStack(alignment: .leading) {
                            Text(token.symbol)
                                .font(.title)
                                .bold()
                            Text(token.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        WatchlistButton(token: token)
                    }
                    .padding()
                    
                    // Price section
                    VStack(spacing: 8) {
                        if let priceString = priceFormatter.string(from: NSNumber(value: token.price)) {
                            Text(priceString)
                                .font(.system(size: 36, weight: .bold))
                        }
                        
                        HStack {
                            Image(systemName: token.change24h >= 0 ? "arrow.up.right" : "arrow.down.right")
                            if let changeString = percentFormatter.string(from: NSNumber(value: abs(token.change24h))) {
                                Text("\(changeString)%")
                            }
                        }
                        .foregroundColor(token.change24h >= 0 ? .green : .red)
                        .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Market data section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Market Data")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            MarketDataRow(
                                title: "Market Cap",
                                value: priceFormatter.string(from: NSNumber(value: token.marketCap / 1_000_000)) ?? "N/A"
                            )
                            MarketDataRow(
                                title: "24h Volume",
                                value: priceFormatter.string(from: NSNumber(value: token.volume24h / 1_000_000)) ?? "N/A"
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Social metrics section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Social Metrics")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            SocialMetricRow(title: "Twitter", value: token.twitterFollowers, icon: "bird")
                            SocialMetricRow(title: "Reddit", value: token.redditSubscribers, icon: "message.fill")
                            SocialMetricRow(title: "GitHub", value: token.githubStars, icon: "star.fill")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Sentiment section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Market Sentiment")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            SentimentBar(value: token.bullishPercentage, color: .green, label: "Bullish")
                            SentimentBar(value: token.neutralPercentage, color: .yellow, label: "Neutral")
                            SentimentBar(value: token.bearishPercentage, color: .red, label: "Bearish")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Helper components

struct MarketDataRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

struct SocialMetricRow: View {
    let title: String
    let value: Int
    let icon: String
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(numberFormatter.string(from: NSNumber(value: value)) ?? "N/A")
                .bold()
        }
    }
}

struct SentimentBar: View {
    let value: Double
    let color: Color
    let label: String
    
    private let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    var body: some View {
        VStack {
            if let percentString = percentFormatter.string(from: NSNumber(value: value)) {
                Text("\(percentString)%")
                    .font(.caption)
            }
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(height: 8)
                    .frame(width: geometry.size.width * value / 100)
            }
            .frame(height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
} 