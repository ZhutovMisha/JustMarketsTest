//
//  MarketCandle.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation

nonisolated struct MarketCandle: Sendable, Equatable {
    
    let openTime: Date
    let open: Decimal
    let high: Decimal
    let low: Decimal
    let close: Decimal
}
