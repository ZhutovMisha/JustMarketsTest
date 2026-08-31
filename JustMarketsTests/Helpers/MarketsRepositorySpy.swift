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
    
    /// Completes a pending symbol-loading operation with the provided symbols.
    /// - Parameter symbols: The symbols to return from the pending operation.
    func completeLoading(with symbols: [MarketSymbol]) {
        fetchContinuation?.resume(returning: symbols)
        fetchContinuation = nil
    }
    
    /// Publishes a market update to the active update stream.
    /// - Parameter update: The market update to publish.
    func emit(_ update: MarketsUpdate) {
        updatesContinuation?.yield(update)
    }
    
}

// MARK: - MarketsRepository

extension MarketsRepositorySpy: MarketsRepository {
    
    /// Fetches the available market symbols.
    ///
    /// - Returns: The available market symbols.
    /// - Throws: The configured error when symbol loading fails.
    func fetchSymbols() async throws -> [MarketSymbol] {
        messages.append(.fetchSymbols)
        
        if let symbolsResult {
            return try symbolsResult.get()
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            fetchContinuation = continuation
        }
    }
    
    /// Observes market updates for the specified symbols.
    /// - Parameter symbols: The symbols whose market updates should be observed.
    /// - Returns: A stream of market updates for the specified symbols.
    func updates(for symbols: [String]) -> AsyncStream<MarketsUpdate> {
        messages.append(.observeUpdates(symbols))
        
        return AsyncStream { self.updatesContinuation = $0 }
    }
}
