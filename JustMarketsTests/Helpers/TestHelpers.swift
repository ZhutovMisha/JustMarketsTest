//
//  TestHelpers.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation
import Testing
@testable import JustMarkets

/// Creates a generic error for use in tests.
/// - Returns: An `NSError` with the domain `"any"` and code `0`.
func anyNSError() -> NSError {
    NSError(domain: "any", code: 0)
}

/// Creates a market symbol with configurable market metadata.
/// - Parameters:
///   - name: The symbol name.
///   - type: The market category.
///   - digits: The number of decimal places used for prices.
///   - isActive: Whether the symbol is active.
///   - hasData: Whether market data is available.
/// - Returns: A market symbol configured with the provided values.
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

/// Creates a market quote with configurable symbol, prices, daily change, and update time.
///
/// - Parameters:
///   - symbol: The quote's symbol.
///   - price: The quote's current price.
///   - bid: The bid price.
///   - ask: The ask price.
///   - change: The daily percentage change.
///   - updatedAt: The quote's update time.
/// - Returns: A market quote configured with the specified values.
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

/// Waits for a main-actor condition to become true within a configurable number of attempts.
/// - Parameters:
///   - attempts: The maximum number of times to evaluate the condition.
///   - sourceLocation: The source location reported if the condition is not met.
///   - condition: The condition to evaluate.
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

/// Creates a market tick with configurable symbol, prices, and daily percentage change.
/// - Parameters:
///   - symbol: The symbol associated with the tick.
///   - mid: The midpoint price.
///   - bid: The bid price.
///   - ask: The ask price.
///   - change: The daily percentage change.
/// - Returns: A market tick containing the specified values.
func makeTick(
    _ symbol: String = "EURUSD",
    mid: Decimal = 1,
    bid: Decimal = 1,
    ask: Decimal = 1,
    change: Decimal = 0
) -> MarketTickDTO {
    MarketTickDTO(symbol: symbol, bid: bid, ask: ask, mid: mid, dayDiffPercent: change)
}

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
