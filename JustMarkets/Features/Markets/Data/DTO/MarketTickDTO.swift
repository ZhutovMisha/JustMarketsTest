//
//  MarketTickDTO.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import Foundation

struct MarketTickDTO: Decodable {
    
    let symbol: String
    let bid: Decimal
    let ask: Decimal
    let mid: Decimal
    let dayDiffPercent: Decimal
}
