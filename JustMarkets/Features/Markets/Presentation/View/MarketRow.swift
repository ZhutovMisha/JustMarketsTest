//
//  MarketRow.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

struct MarketRow {
    
    enum Trend {
        
        case up
        case down
        case flat
    }
    
    let symbol: String
    let name: String
    let price: String
    let change: String
    let trend: Trend
    let status: MarketStatus
    let isFavorite: Bool
}
