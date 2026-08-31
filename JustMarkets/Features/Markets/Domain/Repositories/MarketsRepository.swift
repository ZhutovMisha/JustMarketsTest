//
//  MarketsRepository.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

protocol MarketsRepository {
    
    func fetchSymbols() async throws -> [MarketSymbol]
    func updates(for symbols: [String]) -> AsyncStream<MarketsUpdate>
}
