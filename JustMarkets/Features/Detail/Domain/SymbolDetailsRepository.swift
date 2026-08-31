//
//  SymbolDetailsRepository.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 31.08.2026.
//

protocol SymbolDetailsRepository {
    
    func details(for symbol: String) async throws -> SymbolDetails
    func candles(for symbol: String, interval: CandleInterval) async throws -> [MarketCandle]
}
