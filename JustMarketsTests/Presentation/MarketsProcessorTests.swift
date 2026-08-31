//
//  MarketsProcessorTests.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation
import Testing
@testable import JustMarkets

@Suite
struct MarketsProcessorTests {
    
    @Test
    func makeRow_withPriceAboveOne_limitsPriceToTwoDecimals() {
        let sut = makeSUT()
        
        let row = sut.makeRow(
            symbol: makeSymbol("BTCUSD", digits: 5),
            quote: makeQuote("BTCUSD", price: 77673.21456),
            status: .live,
            isFavorite: false
        )
        
        #expect(row.price == "77,673.21")
    }
    
    @Test
    func makeRow_withPriceBelowOne_keepsSymbolDigits() {
        let sut = makeSUT()
        
        let row = sut.makeRow(
            symbol: makeSymbol("DOTUSD", digits: 4),
            quote: makeQuote("DOTUSD", price: 0.8461),
            status: .live,
            isFavorite: false
        )
        
        #expect(row.price == "0.8461")
    }
    
    @Test
    func makeRow_withNegativeDayChange_showsSignedPercentAndDownTrend() {
        let sut = makeSUT()
        
        let row = sut.makeRow(
            symbol: makeSymbol(),
            quote: makeQuote(change: -3.01),
            status: .live,
            isFavorite: false
        )
        
        #expect(row.change == "-3.01%")
        #expect(row.trend == .down)
    }
}

// MARK: - Helpers

private extension MarketsProcessorTests {
    
    func makeSUT() -> MarketsProcessor {
        MarketsProcessor(locale: Locale(identifier: "en_US_POSIX"))
    }
}
