//
//  MarketType.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

nonisolated enum MarketType: String, Sendable {
    
    case forex = "Forex"
    case stock = "Stock"
    case crypto = "Crypto"
    case commodity = "Commodity"
    case index = "Index"
    case future = "Future"
}
