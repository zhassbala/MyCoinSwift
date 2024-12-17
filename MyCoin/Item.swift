//
//  Item.swift
//  MyCoin
//
//  Created by Rassul Bessimbekov on 11.12.2024.
//

import Foundation
import SwiftData

// Data Transfer Objects for network operations
struct TokenDTO: Codable {
    let codrepoPerc: Double
    let fbPerc: Double
    let redditPerc: Double
    let twitterPerc: Double
    let imageUrl: String
    let fullname: String
    let symbol: String
    let totalPerc: Double
    let bullish: Int
    let neutral: Int
    let bearish: Int
    let cryptocompareId: String
    let coinname: String
    let codrepoData: Int?
    let facebookData: Int?
    let redditData: Int?
    let twitterData: Int?
    let techIndicators: Int?
    let codrepo: CodeRepoData?
    let facebook: FacebookData?
    let reddit: RedditData?
    let twitter: TwitterData?
    
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
}

// Nested models for detailed token information
@Model
final class CodeRepoData: Codable {
    var id: Int
    var closedTotalIssues: Int
    var contributors: Int
    var createdAt: Int64
    var forks: Int
    var lastPush: Int64
    var lastUpdate: Int64
    var points: Int
    var stars: Int
    var subscribers: Int
    var token: Int
    
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
    
    init(id: Int, closedTotalIssues: Int, contributors: Int, createdAt: Int64, forks: Int, lastPush: Int64, lastUpdate: Int64, points: Int, stars: Int, subscribers: Int, token: Int) {
        self.id = id
        self.closedTotalIssues = closedTotalIssues
        self.contributors = contributors
        self.createdAt = createdAt
        self.forks = forks
        self.lastPush = lastPush
        self.lastUpdate = lastUpdate
        self.points = points
        self.stars = stars
        self.subscribers = subscribers
        self.token = token
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        closedTotalIssues = try container.decode(Int.self, forKey: .closedTotalIssues)
        contributors = try container.decode(Int.self, forKey: .contributors)
        createdAt = try container.decode(Int64.self, forKey: .createdAt)
        forks = try container.decode(Int.self, forKey: .forks)
        lastPush = try container.decode(Int64.self, forKey: .lastPush)
        lastUpdate = try container.decode(Int64.self, forKey: .lastUpdate)
        points = try container.decode(Int.self, forKey: .points)
        stars = try container.decode(Int.self, forKey: .stars)
        subscribers = try container.decode(Int.self, forKey: .subscribers)
        token = try container.decode(Int.self, forKey: .token)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(closedTotalIssues, forKey: .closedTotalIssues)
        try container.encode(contributors, forKey: .contributors)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(forks, forKey: .forks)
        try container.encode(lastPush, forKey: .lastPush)
        try container.encode(lastUpdate, forKey: .lastUpdate)
        try container.encode(points, forKey: .points)
        try container.encode(stars, forKey: .stars)
        try container.encode(subscribers, forKey: .subscribers)
        try container.encode(token, forKey: .token)
    }
}

@Model
final class FacebookData: Codable {
    var id: Int
    var isClosed: Bool
    var likes: Int
    var points: Int
    var talkingAbout: Int
    var token: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case isClosed = "is_closed"
        case likes
        case points
        case talkingAbout = "talking_about"
        case token
    }
    
    init(id: Int, isClosed: Bool, likes: Int, points: Int, talkingAbout: Int, token: Int) {
        self.id = id
        self.isClosed = isClosed
        self.likes = likes
        self.points = points
        self.talkingAbout = talkingAbout
        self.token = token
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        isClosed = try container.decode(Bool.self, forKey: .isClosed)
        likes = try container.decode(Int.self, forKey: .likes)
        points = try container.decode(Int.self, forKey: .points)
        talkingAbout = try container.decode(Int.self, forKey: .talkingAbout)
        token = try container.decode(Int.self, forKey: .token)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(isClosed, forKey: .isClosed)
        try container.encode(likes, forKey: .likes)
        try container.encode(points, forKey: .points)
        try container.encode(talkingAbout, forKey: .talkingAbout)
        try container.encode(token, forKey: .token)
    }
}

@Model
final class RedditData: Codable {
    var id: Int
    var activeUsers: Int
    var commentsPerDay: Double
    var commentsPerHour: Double
    var communityCreation: Int64
    var points: Int
    var postsPerDay: Double
    var postsPerHour: Double
    var subscribers: Int
    var token: Int
    
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
    
    init(id: Int, activeUsers: Int, commentsPerDay: Double, commentsPerHour: Double, communityCreation: Int64, points: Int, postsPerDay: Double, postsPerHour: Double, subscribers: Int, token: Int) {
        self.id = id
        self.activeUsers = activeUsers
        self.commentsPerDay = commentsPerDay
        self.commentsPerHour = commentsPerHour
        self.communityCreation = communityCreation
        self.points = points
        self.postsPerDay = postsPerDay
        self.postsPerHour = postsPerHour
        self.subscribers = subscribers
        self.token = token
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        activeUsers = try container.decode(Int.self, forKey: .activeUsers)
        commentsPerDay = try container.decode(Double.self, forKey: .commentsPerDay)
        commentsPerHour = try container.decode(Double.self, forKey: .commentsPerHour)
        communityCreation = try container.decode(Int64.self, forKey: .communityCreation)
        points = try container.decode(Int.self, forKey: .points)
        postsPerDay = try container.decode(Double.self, forKey: .postsPerDay)
        postsPerHour = try container.decode(Double.self, forKey: .postsPerHour)
        subscribers = try container.decode(Int.self, forKey: .subscribers)
        token = try container.decode(Int.self, forKey: .token)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(activeUsers, forKey: .activeUsers)
        try container.encode(commentsPerDay, forKey: .commentsPerDay)
        try container.encode(commentsPerHour, forKey: .commentsPerHour)
        try container.encode(communityCreation, forKey: .communityCreation)
        try container.encode(points, forKey: .points)
        try container.encode(postsPerDay, forKey: .postsPerDay)
        try container.encode(postsPerHour, forKey: .postsPerHour)
        try container.encode(subscribers, forKey: .subscribers)
        try container.encode(token, forKey: .token)
    }
}

@Model
final class TwitterData: Codable {
    var id: Int
    var accountCreation: Int64
    var favourites: Int
    var followers: Int
    var following: Int
    var lists: Int
    var points: Int
    var statuses: Int
    var token: Int
    
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
    
    init(id: Int, accountCreation: Int64, favourites: Int, followers: Int, following: Int, lists: Int, points: Int, statuses: Int, token: Int) {
        self.id = id
        self.accountCreation = accountCreation
        self.favourites = favourites
        self.followers = followers
        self.following = following
        self.lists = lists
        self.points = points
        self.statuses = statuses
        self.token = token
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        accountCreation = try container.decode(Int64.self, forKey: .accountCreation)
        favourites = try container.decode(Int.self, forKey: .favourites)
        followers = try container.decode(Int.self, forKey: .followers)
        following = try container.decode(Int.self, forKey: .following)
        lists = try container.decode(Int.self, forKey: .lists)
        points = try container.decode(Int.self, forKey: .points)
        statuses = try container.decode(Int.self, forKey: .statuses)
        token = try container.decode(Int.self, forKey: .token)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(accountCreation, forKey: .accountCreation)
        try container.encode(favourites, forKey: .favourites)
        try container.encode(followers, forKey: .followers)
        try container.encode(following, forKey: .following)
        try container.encode(lists, forKey: .lists)
        try container.encode(points, forKey: .points)
        try container.encode(statuses, forKey: .statuses)
        try container.encode(token, forKey: .token)
    }
}

@Model
final class Token {
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
    @Relationship(deleteRule: .cascade) var codrepo: CodeRepoData?
    @Relationship(deleteRule: .cascade) var facebook: FacebookData?
    @Relationship(deleteRule: .cascade) var reddit: RedditData?
    @Relationship(deleteRule: .cascade) var twitter: TwitterData?
    
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
    
    convenience init(from dto: TokenDTO) {
        self.init(
            codrepoPerc: dto.codrepoPerc,
            fbPerc: dto.fbPerc,
            redditPerc: dto.redditPerc,
            twitterPerc: dto.twitterPerc,
            imageUrl: dto.imageUrl,
            fullname: dto.fullname,
            symbol: dto.symbol,
            totalPerc: dto.totalPerc,
            bullish: dto.bullish,
            neutral: dto.neutral,
            bearish: dto.bearish,
            cryptocompareId: dto.cryptocompareId,
            coinname: dto.coinname,
            codrepoData: dto.codrepoData,
            facebookData: dto.facebookData,
            redditData: dto.redditData,
            twitterData: dto.twitterData,
            techIndicators: dto.techIndicators,
            codrepo: dto.codrepo,
            facebook: dto.facebook,
            reddit: dto.reddit,
            twitter: dto.twitter
        )
    }
}
