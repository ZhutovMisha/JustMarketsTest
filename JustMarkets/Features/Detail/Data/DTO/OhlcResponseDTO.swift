//
//  OhlcResponseDTO.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation

nonisolated struct OhlcResponseDTO: Decodable, Sendable {
    
    struct Bar: Decodable, Sendable {
        let openTime: Date
        let open: Decimal
        let high: Decimal
        let low: Decimal
        let close: Decimal
    }
    
    let bars: [Bar]
}
