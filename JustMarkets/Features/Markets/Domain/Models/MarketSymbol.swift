//
//  MarketSymbol.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

struct MarketSymbol: Hashable {
    
    let name: String
    let title: String
    let type: MarketType
    let digits: Int
    let isActive: Bool
    let hasData: Bool
}
