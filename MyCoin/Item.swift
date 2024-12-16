//
//  Item.swift
//  MyCoin
//
//  Created by Rassul Bessimbekov on 11.12.2024.
//

import Foundation
import SwiftData

@Model
final class Token: Codable {
    var cryptocompareId: String
    var cryptocompareSymbol: String
    var cryptocompareCoinname: String
    var cryptocompareFullname: String
    var coingeckoId: String
    var coingeckoSymbol: String
    var coingeckoName: String
    var totalPerc: Double
    var bullish: Int
    var neutral: Int
    var bearish: Int
    var isInWatchlist: Bool
    
    enum CodingKeys: String, CodingKey {
        case cryptocompareId = "cryptocompare_id"
        case cryptocompareSymbol = "cryptocompare_symbol"
        case cryptocompareCoinname = "cryptocompare_coinname"
        case cryptocompareFullname = "cryptocompare_fullname"
        case coingeckoId = "coingecko_id"
        case coingeckoSymbol = "coingecko_symbol"
        case coingeckoName = "coingecko_name"
        case totalPerc = "total_perc"
        case bullish
        case neutral
        case bearish
        case isInWatchlist = "is_in_watchlist"
    }
    
    init(
        cryptocompareId: String,
        cryptocompareSymbol: String,
        cryptocompareCoinname: String,
        cryptocompareFullname: String,
        coingeckoId: String,
        coingeckoSymbol: String,
        coingeckoName: String,
        totalPerc: Double,
        bullish: Int,
        neutral: Int,
        bearish: Int,
        isInWatchlist: Bool = false
    ) {
        self.cryptocompareId = cryptocompareId
        self.cryptocompareSymbol = cryptocompareSymbol
        self.cryptocompareCoinname = cryptocompareCoinname
        self.cryptocompareFullname = cryptocompareFullname
        self.coingeckoId = coingeckoId
        self.coingeckoSymbol = coingeckoSymbol
        self.coingeckoName = coingeckoName
        self.totalPerc = totalPerc
        self.bullish = bullish
        self.neutral = neutral
        self.bearish = bearish
        self.isInWatchlist = isInWatchlist
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cryptocompareId = try container.decode(String.self, forKey: .cryptocompareId)
        cryptocompareSymbol = try container.decode(String.self, forKey: .cryptocompareSymbol)
        cryptocompareCoinname = try container.decode(String.self, forKey: .cryptocompareCoinname)
        cryptocompareFullname = try container.decode(String.self, forKey: .cryptocompareFullname)
        coingeckoId = try container.decode(String.self, forKey: .coingeckoId)
        coingeckoSymbol = try container.decode(String.self, forKey: .coingeckoSymbol)
        coingeckoName = try container.decode(String.self, forKey: .coingeckoName)
        totalPerc = try container.decode(Double.self, forKey: .totalPerc)
        bullish = try container.decode(Int.self, forKey: .bullish)
        neutral = try container.decode(Int.self, forKey: .neutral)
        bearish = try container.decode(Int.self, forKey: .bearish)
        isInWatchlist = try container.decodeIfPresent(Bool.self, forKey: .isInWatchlist) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cryptocompareId, forKey: .cryptocompareId)
        try container.encode(cryptocompareSymbol, forKey: .cryptocompareSymbol)
        try container.encode(cryptocompareCoinname, forKey: .cryptocompareCoinname)
        try container.encode(cryptocompareFullname, forKey: .cryptocompareFullname)
        try container.encode(coingeckoId, forKey: .coingeckoId)
        try container.encode(coingeckoSymbol, forKey: .coingeckoSymbol)
        try container.encode(coingeckoName, forKey: .coingeckoName)
        try container.encode(totalPerc, forKey: .totalPerc)
        try container.encode(bullish, forKey: .bullish)
        try container.encode(neutral, forKey: .neutral)
        try container.encode(bearish, forKey: .bearish)
        try container.encode(isInWatchlist, forKey: .isInWatchlist)
    }
}
