//
//  RemoteMarketsRepository.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import Foundation

final class RemoteMarketsRepository: MarketsRepository {
    
    /// One live consumer of the feed: where to send updates, and which symbols it
    /// put into the socket subscription. The two are always added and dropped
    /// together, so they are one value.
    private struct Consumer {
        
        let continuation: AsyncStream<MarketsUpdate>.Continuation
        let symbols: Set<String>
    }
    
    private let networkClient: NetworkClient
    private let quotesDataSource: MarketsQuotesDataSource
    private let throttle: TickThrottle
    
    private var consumers: [UUID: Consumer] = [:]
    private var latestQuotes: [String: MarketQuote] = [:]
    
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
            self?.broadcast(.connection(state))
        }
        
        throttle.onTicks = { [weak self] ticks in
            self?.handle(ticks)
        }
    }
    
    func fetchSymbols() async throws -> [MarketSymbol] {
        try await networkClient
            .request(MarketsEndpoint.symbols, responseType: [MarketSymbolDTO].self)
            .compactMap(MarketsMapper.map)
    }
    
    func updates(for symbols: [String]) -> AsyncStream<MarketsUpdate> {
        AsyncStream { continuation in
            let id = UUID()
            
            consumers[id] = Consumer(continuation: continuation, symbols: Set(symbols))
            
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.removeConsumer(id)
                }
            }
            
            resubscribe()
            
            let snapshot = symbols.compactMap { latestQuotes[$0] }
            
            guard !snapshot.isEmpty else { return }
            
            continuation.yield(.quotes(snapshot))
        }
    }
    
    private func handle(_ ticks: [MarketTickDTO]) {
        let receivedAt = Date()
        
        let quotes = ticks.map { MarketsMapper.map($0, receivedAt: receivedAt) }
        
        for quote in quotes {
            latestQuotes[quote.symbol] = quote
        }
        
        broadcast(.quotes(quotes))
    }
    
    private func removeConsumer(_ id: UUID) {
        consumers[id] = nil
        
        guard consumers.isEmpty else {
            resubscribe()
            
            return
        }
        
        throttle.stop()
        quotesDataSource.disconnect()
    }
    
    private func resubscribe() {
        let symbols = consumers.values.reduce(into: Set<String>()) {
            $0.formUnion($1.symbols)
        }
        
        guard !symbols.isEmpty else { return }
        
        throttle.start()
        quotesDataSource.connect(symbols: symbols.sorted())
    }
    
    private func broadcast(_ update: MarketsUpdate) {
        for consumer in consumers.values {
            consumer.continuation.yield(update)
        }
    }
}
