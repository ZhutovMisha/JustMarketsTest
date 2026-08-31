//
//  TickThrottleTests.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation
import Testing
@testable import JustMarkets

@MainActor
@Suite
final class TickThrottleTests {
    
    private var flushes: [[MarketTickDTO]] = []
    
    
    @Test
    func flush_withRepeatedSymbol_emitsOnlyLatestTick() async {
        let sut = makeSUT()
        
        sut.add(makeTick("EURUSD", mid: 1.1))
        sut.add(makeTick("EURUSD", mid: 1.2))
        sut.add(makeTick("EURUSD", mid: 1.3))
        
        await wait { !flushes.isEmpty }
        
        #expect(flushes.count == 1)
        #expect(flushes.first?.map(\.mid) == [1.3])
    }
    
    @Test
    func flush_withSeveralSymbols_emitsOneTickPerSymbol() async {
        let sut = makeSUT()
        
        sut.add(makeTick("EURUSD", mid: 1.1))
        sut.add(makeTick("GBPUSD", mid: 1.2))
        sut.add(makeTick("EURUSD", mid: 1.3))
        
        await wait { !flushes.isEmpty }
        
        #expect(flushes.first?.map(\.symbol).sorted() == ["EURUSD", "GBPUSD"])
    }
}

// MARK: - Helpers

private extension TickThrottleTests {
    
    func makeSUT() -> TickThrottle {
        let sut = TickThrottle(interval: .milliseconds(10))
        
        sut.onTicks = { [weak self] ticks in
            self?.flushes.append(ticks)
        }
        
        sut.start()
        
        return sut
    }
}
