//
//  Item.swift
//  MyCoin
//
//  Created by Rassul Bessimbekov on 11.12.2024.
//

import Foundation
import SwiftData

// Nested structs for detailed token information
struct CodeRepoData: Codable {
    let id: Int
    let closedTotalIssues: Int
    let contributors: Int
    let createdAt: Int64
    let forks: Int
    let lastPush: Int64
    let lastUpdate: Int64
    let points: Int
    let stars: Int
    let subscribers: Int
    let token: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case closedTotalIssues = "closed_total_issues"
        case contributors
        case createdAt = "created_at"
        case forks
        case lastPush = "last_push"
        case lastUpdate = "last_update"
        case points
        case stars
        case subscribers
        case token
    }
}

struct FacebookData: Codable {
    let id: Int
    let isClosed: Bool
    let likes: Int
    let points: Int
    let talkingAbout: Int
    let token: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case isClosed = "is_closed"
        case likes
        case points
        case talkingAbout = "talking_about"
        case token
    }
}

struct RedditData: Codable {
    let id: Int
    let activeUsers: Int
    let commentsPerDay: Double
    let commentsPerHour: Double
    let communityCreation: Int64
    let points: Int
    let postsPerDay: Double
    let postsPerHour: Double
    let subscribers: Int
    let token: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case activeUsers = "active_users"
        case commentsPerDay = "comments_per_day"
        case commentsPerHour = "comments_per_hour"
        case communityCreation = "community_creation"
        case points
        case postsPerDay = "posts_per_day"
        case postsPerHour = "posts_per_hour"
        case subscribers
        case token
    }
}

struct TwitterData: Codable {
    let id: Int
    let accountCreation: Int64
    let favourites: Int
    let followers: Int
    let following: Int
    let lists: Int
    let points: Int
    let statuses: Int
    let token: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case accountCreation = "account_creation"
        case favourites
        case followers
        case following
        case lists
        case points
        case statuses
        case token
    }
}

@Model
final class Token: Codable {
    var codrepoPerc: Double
    var fbPerc: Double
    var redditPerc: Double
    var twitterPerc: Double
    var imageUrl: String
    var fullname: String
    var symbol: String
    var totalPerc: Double
    var bullish: Int
    var neutral: Int
    var bearish: Int
    var cryptocompareId: String
    var coinname: String
    
    // Detailed data
    var codrepoData: Int?
    var facebookData: Int?
    var redditData: Int?
    var twitterData: Int?
    var techIndicators: Int?
    
    // Detailed objects
    var codrepo: CodeRepoData?
    var facebook: FacebookData?
    var reddit: RedditData?
    var twitter: TwitterData?
    
    enum CodingKeys: String, CodingKey {
        case codrepoPerc = "codrepo_perc"
        case fbPerc = "fb_perc"
        case redditPerc = "reddit_perc"
        case twitterPerc = "twitter_perc"
        case imageUrl = "imageurl"
        case fullname
        case symbol
        case totalPerc = "total_perc"
        case bullish
        case neutral
        case bearish
        case cryptocompareId = "cryptocompare_id"
        case coinname
        case codrepoData = "codrepo_data"
        case facebookData = "facebook_data"
        case redditData = "reddit_data"
        case twitterData = "twitter_data"
        case techIndicators = "techindicators"
        case codrepo
        case facebook
        case reddit
        case twitter
    }
    
    init(
        codrepoPerc: Double,
        fbPerc: Double,
        redditPerc: Double,
        twitterPerc: Double,
        imageUrl: String,
        fullname: String,
        symbol: String,
        totalPerc: Double,
        bullish: Int,
        neutral: Int,
        bearish: Int,
        cryptocompareId: String,
        coinname: String,
        codrepoData: Int? = nil,
        facebookData: Int? = nil,
        redditData: Int? = nil,
        twitterData: Int? = nil,
        techIndicators: Int? = nil,
        codrepo: CodeRepoData? = nil,
        facebook: FacebookData? = nil,
        reddit: RedditData? = nil,
        twitter: TwitterData? = nil
    ) {
        self.codrepoPerc = codrepoPerc
        self.fbPerc = fbPerc
        self.redditPerc = redditPerc
        self.twitterPerc = twitterPerc
        self.imageUrl = imageUrl
        self.fullname = fullname
        self.symbol = symbol
        self.totalPerc = totalPerc
        self.bullish = bullish
        self.neutral = neutral
        self.bearish = bearish
        self.cryptocompareId = cryptocompareId
        self.coinname = coinname
        self.codrepoData = codrepoData
        self.facebookData = facebookData
        self.redditData = redditData
        self.twitterData = twitterData
        self.techIndicators = techIndicators
        self.codrepo = codrepo
        self.facebook = facebook
        self.reddit = reddit
        self.twitter = twitter
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        codrepoPerc = try container.decode(Double.self, forKey: .codrepoPerc)
        fbPerc = try container.decode(Double.self, forKey: .fbPerc)
        redditPerc = try container.decode(Double.self, forKey: .redditPerc)
        twitterPerc = try container.decode(Double.self, forKey: .twitterPerc)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        fullname = try container.decode(String.self, forKey: .fullname)
        symbol = try container.decode(String.self, forKey: .symbol)
        totalPerc = try container.decode(Double.self, forKey: .totalPerc)
        bullish = try container.decode(Int.self, forKey: .bullish)
        neutral = try container.decode(Int.self, forKey: .neutral)
        bearish = try container.decode(Int.self, forKey: .bearish)
        cryptocompareId = try container.decode(String.self, forKey: .cryptocompareId)
        coinname = try container.decode(String.self, forKey: .coinname)
        
        // Decode detailed data
        codrepoData = try container.decodeIfPresent(Int.self, forKey: .codrepoData)
        facebookData = try container.decodeIfPresent(Int.self, forKey: .facebookData)
        redditData = try container.decodeIfPresent(Int.self, forKey: .redditData)
        twitterData = try container.decodeIfPresent(Int.self, forKey: .twitterData)
        techIndicators = try container.decodeIfPresent(Int.self, forKey: .techIndicators)
        
        // Decode detailed objects
        codrepo = try container.decodeIfPresent(CodeRepoData.self, forKey: .codrepo)
        facebook = try container.decodeIfPresent(FacebookData.self, forKey: .facebook)
        reddit = try container.decodeIfPresent(RedditData.self, forKey: .reddit)
        twitter = try container.decodeIfPresent(TwitterData.self, forKey: .twitter)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(codrepoPerc, forKey: .codrepoPerc)
        try container.encode(fbPerc, forKey: .fbPerc)
        try container.encode(redditPerc, forKey: .redditPerc)
        try container.encode(twitterPerc, forKey: .twitterPerc)
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encode(fullname, forKey: .fullname)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(totalPerc, forKey: .totalPerc)
        try container.encode(bullish, forKey: .bullish)
        try container.encode(neutral, forKey: .neutral)
        try container.encode(bearish, forKey: .bearish)
        try container.encode(cryptocompareId, forKey: .cryptocompareId)
        try container.encode(coinname, forKey: .coinname)
        
        // Encode detailed data
        try container.encodeIfPresent(codrepoData, forKey: .codrepoData)
        try container.encodeIfPresent(facebookData, forKey: .facebookData)
        try container.encodeIfPresent(redditData, forKey: .redditData)
        try container.encodeIfPresent(twitterData, forKey: .twitterData)
        try container.encodeIfPresent(techIndicators, forKey: .techIndicators)
        
        // Encode detailed objects
        try container.encodeIfPresent(codrepo, forKey: .codrepo)
        try container.encodeIfPresent(facebook, forKey: .facebook)
        try container.encodeIfPresent(reddit, forKey: .reddit)
        try container.encodeIfPresent(twitter, forKey: .twitter)
    }
}
