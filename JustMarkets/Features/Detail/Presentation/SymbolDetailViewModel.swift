//
//  SymbolDetailViewModel.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation

@MainActor
final class SymbolDetailViewModel {
    
    typealias OnChange = () -> Void
    typealias OnLoadingChanged = (Bool) -> Void
    typealias OnQuoteChanged = () -> Void
    typealias OnError = (Error) -> Void
    
    struct Dependencies {
        
        let detailsRepository: SymbolDetailsRepository
        let marketsRepository: MarketsRepository
        let processor: MarketsProcessor
    }
    
    var onChange: OnChange?
    var onLoadingChanged: OnLoadingChanged?
    var onQuoteChanged: OnQuoteChanged?
    var onError: OnError?
    
    let symbol: MarketSymbol
    let intervals = CandleInterval.allCases
    
    private(set) var selectedInterval: CandleInterval = .oneHour
    private(set) var candles: [MarketCandle] = []
    
    private let dependencies: Dependencies
    private var details: SymbolDetails?
    private var quote: MarketQuote?
    private var updatesTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?
    
    init(symbol: MarketSymbol, dependencies: Dependencies) {
        self.symbol = symbol
        self.dependencies = dependencies
    }
    
    deinit {
        updatesTask?.cancel()
        loadTask?.cancel()
    }
    
    var title: String {
        symbol.name
    }
    
    var subtitle: String {
        symbol.title
    }
    
    var status: MarketStatus {
        MarketStatus(symbol: symbol, quote: quote, now: Date())
    }
    
    var price: String {
        dependencies.processor.price(quote?.price, digits: symbol.digits)
    }
    
    var change: String {
        dependencies.processor.change(quote?.dayChangePercent)
    }
    
    var trend: MarketRow.Trend {
        dependencies.processor.trend(quote?.dayChangePercent)
    }
    
    var quoteRows: [SymbolDetailInfoRow] {
        [
            SymbolDetailInfoRow(title: "Bid", value: price(quote?.bid)),
            SymbolDetailInfoRow(title: "Ask", value: price(quote?.ask)),
            SymbolDetailInfoRow(title: "Spread", value: price(quote?.spread))
        ]
    }
    
    var specRows: [SymbolDetailInfoRow] {
        guard let details else { return [] }
        
        return [
            SymbolDetailInfoRow(title: "Exchange", value: details.exchange),
            SymbolDetailInfoRow(title: "Currency", value: details.currency),
            SymbolDetailInfoRow(title: "Contract size", value: amount(details.contractSize)),
            SymbolDetailInfoRow(title: "Tick size", value: amount(details.tickSize))
        ]
    }
    
    /// Loads the symbol details and candle data, replacing any active load operation.
    func load() {
        loadTask?.cancel()
        
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }
    
    /// Loads the symbol’s details and candles for the selected interval, then begins observing quote updates.
    private func performLoad() async {
        onLoadingChanged?(true)
        
        defer {
            // A newer load already owns the indicator.
            if !Task.isCancelled {
                onLoadingChanged?(false)
            }
        }
        
        do {
            async let details = dependencies.detailsRepository.details(for: symbol.name)
            async let candles = dependencies.detailsRepository.candles(for: symbol.name, interval: selectedInterval)
            
            let loadedDetails = try await details
            let loadedCandles = try await candles
            
            guard !Task.isCancelled else { return }
            
            self.details = loadedDetails
            self.candles = loadedCandles
            
            onChange?()
            
            observeQuotes()
        } catch {
            guard !Task.isCancelled else { return }
            
            onError?(error)
        }
    }
    
    /// Selects a candle interval and loads candles for it.
    /// - Parameter interval: The candle interval to select.
    func selectInterval(_ interval: CandleInterval) {
        guard interval != selectedInterval else { return }
        
        selectedInterval = interval
        
        loadTask?.cancel()
        
        loadTask = Task { [weak self] in
            await self?.performLoadCandles(for: interval)
        }
    }
    
    /// Loads candle data for the specified interval and updates observers when the data is available.
    /// - Parameter interval: The candle interval to load.
    private func performLoadCandles(for interval: CandleInterval) async {
        onLoadingChanged?(true)
        
        defer {
            // A newer load already owns the indicator.
            if !Task.isCancelled {
                onLoadingChanged?(false)
            }
        }
        
        do {
            let loaded = try await dependencies.detailsRepository.candles(for: symbol.name, interval: interval)
            
            guard !Task.isCancelled else { return }
            
            candles = loaded
            
            onChange?()
        } catch {
            guard !Task.isCancelled else { return }
            
            onError?(error)
        }
    }
    
    /// Formats a price value using the symbol's configured number of digits.
    /// - Parameter value: The price value to format.
    /// - Returns: The formatted price string.
    private func price(_ value: Decimal?) -> String {
        dependencies.processor.price(value, digits: symbol.digits)
    }
    
    /// Formats a decimal amount for display.
    private func amount(_ value: Decimal) -> String {
        dependencies.processor.amount(value)
    }
    
    /// Observes market updates for the current symbol and applies matching quotes.
    private func observeQuotes() {
        let name = symbol.name
        
        let updates = dependencies.marketsRepository.updates(for: [name])
        
        updatesTask?.cancel()
        
        updatesTask = Task { [weak self] in
            for await update in updates {
                guard
                    case .quotes(let quotes) = update,
                    let quote = quotes.first(where: { $0.symbol == name })
                else {
                    continue
                }
                
                self?.apply(quote)
            }
        }
    }
    
    /// Applies a market quote and notifies observers of the update.
    private func apply(_ quote: MarketQuote) {
        self.quote = quote
        onQuoteChanged?()
    }
}
