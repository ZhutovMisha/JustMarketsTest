//
//  MarketsFilterTests.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Testing
@testable import JustMarkets

@Suite
struct MarketsFilterTests {
    
    @Test
    func symbols_withCryptoCategory_excludesPairsNotQuotedInUSD() {
        let result = MarketsFilter.symbols(mixedSymbols(), category: .crypto, favorites: [], query: "")
        
        #expect(result.map(\.name) == ["BTCUSD"])
    }
    
    @Test
    func symbols_withQuery_matchesSymbolNameCaseInsensitively() {
        let result = MarketsFilter.symbols(mixedSymbols(), category: .all, favorites: [], query: "btc")
        
        #expect(result.map(\.name) == ["BTCUSD", "BTCJPY"])
    }
    
    @Test
    func symbols_withFavorites_putsThemFirstInFavoritesOrder() {
        let result = MarketsFilter.symbols(
            mixedSymbols(),
            category: .all,
            favorites: ["AAPL", "BTCJPY"],
            query: ""
        )
        
        #expect(result.map(\.name) == ["AAPL", "BTCJPY", "EURUSD", "BTCUSD"])
    }
}

// MARK: - Helpers

private extension MarketsFilterTests {
    
    func mixedSymbols() -> [MarketSymbol] {
        [
            makeSymbol("EURUSD", type: .forex),
            makeSymbol("BTCUSD", type: .crypto),
            makeSymbol("BTCJPY", type: .crypto),
            makeSymbol("AAPL", type: .stock)
        ]
    }
}
