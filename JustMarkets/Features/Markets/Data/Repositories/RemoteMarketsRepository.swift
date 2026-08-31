//
//  RemoteMarketsRepository.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import Foundation

@MainActor
final class RemoteMarketsRepository: MarketsRepository {
    
    private let networkClient: NetworkClient
    private let quotesDataSource: MarketsQuotesDataSource
    private let throttle: TickThrottle
    
    private var continuation: AsyncStream<MarketsUpdate>.Continuation?
    private var latestQuotes: [String: MarketQuote] = [:]
    private var subscriptionID = 0
    
    init(
        networkClient: NetworkClient,
        quotesDataSource: MarketsQuotesDataSource,
        throttle: TickThrottle
    ) {
        self.networkClient = networkClient
        self.quotesDataSource = quotesDataSource
        self.throttle = throttle
        
        quotesDataSource.onTick = { [weak self] tick in
            self?.throttle.add(tick)
        }
        
        quotesDataSource.onConnectionChanged = { [weak self] state in
            self?.continuation?.yield(.connection(state))
        }
        
        throttle.onTicks = { [weak self] ticks in
            self?.handle(ticks)
        }
    }
    
    /// Fetches the available market symbols.
    /// - Returns: The mapped market symbols.
    func fetchSymbols() async throws -> [MarketSymbol] {
        try await networkClient
            .request(MarketsEndpoint.symbols,responseType: [MarketSymbolDTO].self)
            .compactMap(MarketsMapper.map)
    }
    
    /// Creates a live market update stream for the specified symbols.
    ///
    /// - Parameter symbols: The symbols for which to receive market updates.
    /// - Returns: A stream containing connection-state changes and quote updates for the specified symbols.
    func updates(for symbols: [String]) -> AsyncStream<MarketsUpdate> {
        AsyncStream { continuation in
            subscriptionID += 1
            self.continuation = continuation
            
            let id = subscriptionID
            
            let quotes = symbols.compactMap {
                latestQuotes[$0]
            }
            
            if !quotes.isEmpty {
                continuation.yield(.quotes(quotes))
            }
            
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.stopFeed(id)
                }
            }
            
            throttle.start()
            quotesDataSource.connect(symbols: symbols)
        }
    }

    /// Stops the active market updates feed for the specified subscription.
    /// - Parameter id: The subscription identifier to stop.
    private func stopFeed(_ id: Int) {
        guard id == subscriptionID else { return }
        
        continuation = nil
        throttle.stop()
        quotesDataSource.disconnect()
    }
    
    /// Processes incoming market ticks, updates the latest quote cache, and publishes the resulting quotes.
    /// - Parameter ticks: The market tick data to process.
    private func handle(_ ticks: [MarketTickDTO]) {
        let receivedAt = Date()
        
        let quotes = ticks.map {
            MarketsMapper.map($0, receivedAt: receivedAt)
        }
        
        for quote in quotes {
            latestQuotes[quote.symbol] = quote
        }
        
        continuation?.yield(.quotes(quotes))
    }
}
