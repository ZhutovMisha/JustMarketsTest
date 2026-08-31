//
//  MarketsFilter.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation

enum MarketsFilter {

    /// Filters market symbols by category and query, placing matching favorites first.
    /// - Parameters:
    ///   - symbols: The market symbols to filter.
    ///   - category: The category used to filter symbols.
    ///   - favorites: The symbol names to prioritize, in display order.
    ///   - query: The name or title text used for case-insensitive matching.
    /// - Returns: Matching symbols with favorites first in the order provided, followed by the remaining matches.
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
    
    /// Determines whether a market symbol matches a search query.
    /// - Parameters:
    ///   - symbol: The market symbol to evaluate.
    ///   - query: The search text.
    /// - Returns: `true` if the query is empty or appears in the symbol's name or title, `false` otherwise.
    private static func matches(_ symbol: MarketSymbol, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        
        return symbol.name.localizedCaseInsensitiveContains(query)
            || symbol.title.localizedCaseInsensitiveContains(query)
    }
    
    /// Determines whether a market symbol belongs to the selected category.
    /// - Parameters:
    ///   - symbol: The market symbol to evaluate.
    ///   - category: The category used for matching.
    ///   - favorites: The names of the user's favorite symbols.
    /// - Returns: `true` if the symbol matches the category, `false` otherwise.
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
