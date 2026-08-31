//
//  MarketQuote.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation

nonisolated struct MarketQuote: Sendable, Equatable {
    
    let symbol: String
    let price: Decimal
    let bid: Decimal
    let ask: Decimal
    let dayChangePercent: Decimal
    let updatedAt: Date
    
    var spread: Decimal {
        ask - bid
    }
}
