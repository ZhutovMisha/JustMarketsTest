//
//  MarketSymbolDTO.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import Foundation


nonisolated struct MarketSymbolDTO: Decodable, Sendable {
    
    let name: String
    let description: String
    let exchange: String
    let type: MarketType
    let digits: Int
    let tickSize: Decimal
    let tickValue: Decimal
    let contractSize: Decimal
    let currency: String
    let source: String
    let isActive: Bool
    let hasData: Bool
}
