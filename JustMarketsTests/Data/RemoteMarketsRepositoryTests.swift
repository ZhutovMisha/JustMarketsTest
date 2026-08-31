//
//  RemoteMarketsRepositoryTests.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation
import Testing
@testable import JustMarkets

@MainActor
@Suite
struct RemoteMarketsRepositoryTests {
    
    @Test
    func fetchSymbols_withUnknownType_skipsSymbol() async throws {
        let (sut, network, _) = makeSUT()
        network.stub(json: """
        [
            { "name": "EURUSD", "description": "Euro", "type": "Forex", "digits": 5, "isActive": true, "hasData": true },
            { "name": "WAT", "description": "Unknown", "type": "Wat", "digits": 2, "isActive": true, "hasData": true }
        ]
        """)
        
        let symbols = try await sut.fetchSymbols()
        
        #expect(symbols.map(\.name) == ["EURUSD"])
        #expect(symbols.first?.type == .forex)
    }
    
    @Test
    func updates_onRepeatedTicks_yieldsSingleThrottledQuote() async {
        let (sut, _, dataSource) = makeSUT()
        var iterator = sut.updates(for: ["EURUSD"]).makeAsyncIterator()
        
        dataSource.simulateTick(makeTick("EURUSD", mid: 1.1))
        dataSource.simulateTick(makeTick("EURUSD", mid: 1.3))
        
        guard case .quotes(let quotes) = await iterator.next() else {
            Issue.record("Expected a quotes update")
            return
        }
        
        #expect(quotes.map(\.symbol) == ["EURUSD"])
        #expect(quotes.map(\.price) == [1.3])
    }
}

// MARK: - Helpers

private extension RemoteMarketsRepositoryTests {
    
    func makeSUT() -> (
        sut: RemoteMarketsRepository,
        network: NetworkClientSpy,
        dataSource: QuotesDataSourceSpy
    ) {
        let network = NetworkClientSpy()
        let dataSource = QuotesDataSourceSpy()
        
        let sut = RemoteMarketsRepository(
            networkClient: network,
            quotesDataSource: dataSource,
            throttle: TickThrottle(interval: .milliseconds(10))
        )
        
        return (sut, network, dataSource)
    }
}
