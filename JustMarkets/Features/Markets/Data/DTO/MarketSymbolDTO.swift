//
//  MarketSymbolDTO.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

nonisolated struct MarketSymbolDTO: Decodable, Sendable {
    
    let name: String
    let description: String
    let type: String
    let digits: Int
    let isActive: Bool
    let hasData: Bool
}
