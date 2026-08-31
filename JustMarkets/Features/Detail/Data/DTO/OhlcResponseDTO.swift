//
//  OhlcResponseDTO.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation

struct OhlcResponseDTO: Decodable {
    
    struct Bar: Decodable {
        let openTime: Date
        let open: Decimal
        let high: Decimal
        let low: Decimal
        let close: Decimal
    }
    
    let bars: [Bar]
}
