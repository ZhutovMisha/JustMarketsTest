//
//  MarketSymbol.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

nonisolated struct MarketSymbol: Sendable, Hashable {
    
    let name: String
    let title: String
    let type: MarketType
    let digits: Int
    let isActive: Bool
    let hasData: Bool
}
