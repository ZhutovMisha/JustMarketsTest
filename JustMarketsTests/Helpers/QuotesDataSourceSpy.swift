//
//  QuotesDataSourceSpy.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

@testable import JustMarkets

@MainActor
final class QuotesDataSourceSpy {
    
    enum Message: Equatable {
        
        case connect([String])
        case disconnect
    }
    
    private(set) var messages: [Message] = []
    
    var onTick: ((MarketTickDTO) -> Void)?
    var onConnectionChanged: ((MarketConnectionState) -> Void)?
    
    /// Simulates receiving a market tick.
    /// - Parameter tick: The market tick to deliver to the callback.
    func simulateTick(_ tick: MarketTickDTO) {
        onTick?(tick)
    }
    
}

// MARK: - MarketsQuotesDataSource

extension QuotesDataSourceSpy: MarketsQuotesDataSource {
    
    /// Records a request to connect to the specified market symbols.
    /// - Parameter symbols: The market symbols to connect to.
    func connect(symbols: [String]) {
        messages.append(.connect(symbols))
    }
    
    /// Records a request to disconnect from the quotes data source.
    func disconnect() {
        messages.append(.disconnect)
    }
}
