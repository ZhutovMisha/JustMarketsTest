//
//  MarketStatus.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 31.08.2026.
//
import Foundation

enum MarketStatus: Equatable {
    
    static let staleInterval: TimeInterval = 60
    
    case live
    case closed
    case noData
    case stale
    
    init(
        symbol: MarketSymbol,
        quote: MarketQuote?,
        now: Date,
        staleInterval: TimeInterval = Self.staleInterval
    ) {
        guard let quote else {
            guard symbol.hasData else {
                self = symbol.type == .crypto ? .noData : .closed
                return
            }
            
            self = .live
            return
        }
        
        self = now.timeIntervalSince(quote.updatedAt) > staleInterval
            ? .stale
            : .live
    }
}
