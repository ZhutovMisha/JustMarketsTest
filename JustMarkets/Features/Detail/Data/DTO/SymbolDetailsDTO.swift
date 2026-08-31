//
//  SymbolDetailsDTO.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation

struct SymbolDetailsDTO: Decodable {
    
    let name: String
    let description: String
    let exchange: String
    let currency: String
    let contractSize: Decimal
    let tickSize: Decimal
    let digits: Int
    let isActive: Bool
}
