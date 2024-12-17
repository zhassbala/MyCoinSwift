import Foundation

// Main Token model, similar to TypeScript interface or type
// Identifiable is like having an 'id' field in your TypeScript interface
// Codable is like having a type that can be JSON.parse'd and JSON.stringify'd
// Equatable is like being able to use === comparison in JavaScript
struct Token: Identifiable, Codable, Equatable {
    let id: String
    let symbol: String
    let name: String
    let fullName: String
    let imageUrl: String?        // Optional, like string | null in TypeScript
    let price: Double
    let marketCap: Double
    let volume24h: Double
    let change24h: Double
    let isInWatchlist: Bool
    
    // Social metrics - like having a nested social object in JavaScript
    let twitterFollowers: Int
    let redditSubscribers: Int
    let githubStars: Int
    
    // Sentiment metrics - like having a nested sentiment object in JavaScript
    let bullishPercentage: Double
    let bearishPercentage: Double
    let neutralPercentage: Double
    
    // CodingKeys is like defining a schema for JSON serialization
    // Similar to how you'd map API response fields in JavaScript:
    // const mapApiResponse = (data) => ({
    //   id: data.cryptocompare_id,
    //   symbol: data.symbol,
    //   ...
    // })
    enum CodingKeys: String, CodingKey {
        case id = "cryptocompare_id"
        case symbol
        case name = "coinname"
        case fullName = "fullname"
        case imageUrl = "image_url"
        case price
        case marketCap = "market_cap"
        case volume24h = "volume_24h"
        case change24h = "change_24h"
        case isInWatchlist = "is_in_watchlist"
        case twitterFollowers = "twitter_followers"
        case redditSubscribers = "reddit_subscribers"
        case githubStars = "github_stars"
        case bullishPercentage = "bullish_percentage"
        case bearishPercentage = "bearish_percentage"
        case neutralPercentage = "neutral_percentage"
    }
}

// API Response Models - similar to TypeScript interfaces for API responses
struct TokenResponse: Codable {
    let id: String
    let symbol: String
    let name: String
    let fullName: String
    let imageUrl: String?
    let price: Double
    let marketCap: Double
    let volume24h: Double
    let change24h: Double
    let socialMetrics: SocialMetrics       // Nested object, like in REST API responses
    let sentimentMetrics: SentimentMetrics // Nested object, like in REST API responses
    
    enum CodingKeys: String, CodingKey {
        case id = "cryptocompare_id"
        case symbol
        case name = "coinname"
        case fullName = "fullname"
        case imageUrl = "image_url"
        case price
        case marketCap = "market_cap"
        case volume24h = "volume_24h"
        case change24h = "change_24h"
        case socialMetrics = "social_metrics"
        case sentimentMetrics = "sentiment_metrics"
    }
}

// Nested object for social metrics
// Similar to:
// interface SocialMetrics {
//   twitterFollowers: number;
//   redditSubscribers: number;
//   githubStars: number;
// }
struct SocialMetrics: Codable {
    let twitterFollowers: Int
    let redditSubscribers: Int
    let githubStars: Int
    
    enum CodingKeys: String, CodingKey {
        case twitterFollowers = "twitter_followers"
        case redditSubscribers = "reddit_subscribers"
        case githubStars = "github_stars"
    }
}

// Nested object for sentiment metrics
// Similar to:
// interface SentimentMetrics {
//   bullishPercentage: number;
//   bearishPercentage: number;
//   neutralPercentage: number;
// }
struct SentimentMetrics: Codable {
    let bullishPercentage: Double
    let bearishPercentage: Double
    let neutralPercentage: Double
    
    enum CodingKeys: String, CodingKey {
        case bullishPercentage = "bullish_percentage"
        case bearishPercentage = "bearish_percentage"
        case neutralPercentage = "neutral_percentage"
    }
} 