//
//  MarketStatusTests.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 31.08.2026.
//

import Foundation
import Testing
@testable import JustMarkets

@Suite
struct MarketStatusTests {
    
    @Test
    func init_withoutData_isClosedForSessionBasedMarket() {
        let status = MarketStatus(
            symbol: makeSymbol("EURUSD", type: .forex, hasData: false),
            quote: nil,
            now: Date()
        )
        
        #expect(status == .closed)
    }
    
    @Test
    func init_withoutData_isNoDataForCrypto() {
        let status = MarketStatus(
            symbol: makeSymbol("BTCUSD", type: .crypto, hasData: false),
            quote: nil,
            now: Date()
        )
        
        #expect(status == .noData)
    }
    
    @Test
    func init_withQuote_isStaleOnlyPastTheStalenessWindow() {
        let now = Date()
        
        let fresh = MarketStatus(
            symbol: makeSymbol("BTCUSD", type: .crypto),
            quote: makeQuote("BTCUSD", updatedAt: now.addingTimeInterval(-59)),
            now: now
        )
        
        let outdated = MarketStatus(
            symbol: makeSymbol("BTCUSD", type: .crypto),
            quote: makeQuote("BTCUSD", updatedAt: now.addingTimeInterval(-61)),
            now: now
        )
        
        #expect(fresh == .live)
        #expect(outdated == .stale)
    }
}
