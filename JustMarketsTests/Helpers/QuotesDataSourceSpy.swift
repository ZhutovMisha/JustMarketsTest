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
    
    func simulateTick(_ tick: MarketTickDTO) {
        onTick?(tick)
    }
    
}

// MARK: - MarketsQuotesDataSource

extension QuotesDataSourceSpy: MarketsQuotesDataSource {
    
    func connect(symbols: [String]) {
        messages.append(.connect(symbols))
    }
    
    func disconnect() {
        messages.append(.disconnect)
    }
}
