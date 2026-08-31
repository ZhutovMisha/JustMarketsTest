//
//  MarketsRepositorySpy.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

@testable import JustMarkets

@MainActor
final class MarketsRepositorySpy {
    
    enum Message: Equatable {
        
        case fetchSymbols
        case observeUpdates([String])
    }
    
    private(set) var messages: [Message] = []
    
    var symbolsResult: Result<[MarketSymbol], Error>?
    
    private var fetchContinuation: CheckedContinuation<[MarketSymbol], Error>?
    private var updatesContinuation: AsyncStream<MarketsUpdate>.Continuation?
    
    func completeLoading(with symbols: [MarketSymbol]) {
        fetchContinuation?.resume(returning: symbols)
        fetchContinuation = nil
    }
    
    func emit(_ update: MarketsUpdate) {
        updatesContinuation?.yield(update)
    }
    
}

// MARK: - MarketsRepository

extension MarketsRepositorySpy: MarketsRepository {
    
    func fetchSymbols() async throws -> [MarketSymbol] {
        messages.append(.fetchSymbols)
        
        if let symbolsResult {
            return try symbolsResult.get()
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            fetchContinuation = continuation
        }
    }
    
    func updates(for symbols: [String]) -> AsyncStream<MarketsUpdate> {
        messages.append(.observeUpdates(symbols))
        
        return AsyncStream { self.updatesContinuation = $0 }
    }
}
