//
//  TestHelpers.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation
import Testing
@testable import JustMarkets

func makeSymbol(
    _ name: String = "EURUSD",
    type: MarketType = .forex,
    digits: Int = 5,
    isActive: Bool = true,
    hasData: Bool = true
) -> MarketSymbol {
    MarketSymbol(
        name: name,
        title: "\(name) description",
        type: type,
        digits: digits,
        isActive: isActive,
        hasData: hasData
    )
}

func makeQuote(
    _ symbol: String = "EURUSD",
    price: Decimal = 1,
    bid: Decimal = 1,
    ask: Decimal = 1,
    change: Decimal = 0,
    updatedAt: Date = Date()
) -> MarketQuote {
    MarketQuote(
        symbol: symbol,
        price: price,
        bid: bid,
        ask: ask,
        dayChangePercent: change,
        updatedAt: updatedAt
    )
}

@MainActor
func wait(
    attempts: Int = 200,
    sourceLocation: SourceLocation = #_sourceLocation,
    until condition: @MainActor () -> Bool
) async {
    for _ in 0..<attempts {
        if condition() {
            return
        }
        
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(1))
    }
    
    Issue.record("Condition was never met", sourceLocation: sourceLocation)
}

func makeTick(
    _ symbol: String = "EURUSD",
    mid: Decimal = 1,
    bid: Decimal = 1,
    ask: Decimal = 1,
    change: Decimal = 0
) -> MarketTickDTO {
    MarketTickDTO(symbol: symbol, bid: bid, ask: ask, mid: mid, dayDiffPercent: change)
}

/// Kicks off a load and waits for the view model to report it finished.
@MainActor
func loadAndWait(_ sut: MarketsViewModel, sourceLocation: SourceLocation = #_sourceLocation) async {
    var isFinished = false
    
    let previous = sut.onLoadingChanged
    
    sut.onLoadingChanged = { isLoading in
        previous?(isLoading)
        
        if !isLoading {
            isFinished = true
        }
    }
    
    sut.loadData()
    
    await wait(sourceLocation: sourceLocation) { isFinished }
    
    sut.onLoadingChanged = previous
}
