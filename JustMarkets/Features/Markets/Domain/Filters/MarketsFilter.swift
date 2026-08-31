//
//  MarketsFilter.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation

enum MarketsFilter {

    static func symbols(
        _ symbols: [MarketSymbol],
        category: MarketCategory,
        favorites: [String],
        query: String
    ) -> [MarketSymbol] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        
        let matched = symbols.filter {
            matches($0, category: category, favorites: favorites)
                && matches($0, query: trimmedQuery)
        }
        
        let pinned = favorites.compactMap { name in
            matched.first { $0.name == name }
        }
        
        let rest = matched.filter { !favorites.contains($0.name) }
        
        return pinned + rest
    }
    
    private static func matches(_ symbol: MarketSymbol, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        
        return symbol.name.localizedCaseInsensitiveContains(query)
            || symbol.title.localizedCaseInsensitiveContains(query)
    }
    
    private static func matches(
        _ symbol: MarketSymbol,
        category: MarketCategory,
        favorites: [String]
    ) -> Bool {
        switch category {
        case .all:
            true

        case .favorites:
            favorites.contains(symbol.name)

        case .forex:
            symbol.type == .forex && symbol.name.hasSuffix("USD")

        case .crypto:
            symbol.type == .crypto && symbol.name.hasSuffix("USD")

        case .stocks:
            symbol.type == .stock

        case .indices:
            symbol.type == .index

        case .commodities:
            symbol.type == .commodity

        case .futures:
            symbol.type == .future
        }
    }
}
