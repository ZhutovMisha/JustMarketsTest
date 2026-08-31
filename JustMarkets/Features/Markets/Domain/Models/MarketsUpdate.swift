//
//  MarketsUpdate.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

enum MarketsUpdate: Equatable {
    
    case quotes([MarketQuote])
    case connection(MarketConnectionState)
}
