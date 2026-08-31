//
//  SymbolDetailViewModel.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation

final class SymbolDetailViewModel {
    
    typealias OnChange = () -> Void
    typealias OnLoadingChanged = (Bool) -> Void
    typealias OnQuoteChanged = () -> Void
    typealias OnError = (Error) -> Void
    
    struct Dependencies {
        
        let detailsRepository: RemoteSymbolDetailsRepository
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
    
    func load() {
        loadTask?.cancel()
        
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }
    
    private func performLoad() async {
        onLoadingChanged?(true)
        
        defer {
            onLoadingChanged?(false)
        }
        
        do {
            async let details = dependencies.detailsRepository.details(for: symbol.name)
            async let candles = dependencies.detailsRepository.candles(for: symbol.name, interval: selectedInterval)
            
            self.details = try await details
            self.candles = try await candles
            
            onChange?()
            
            observeQuotes()
        } catch {
            onError?(error)
        }
    }
    
    func selectInterval(_ interval: CandleInterval) {
        guard interval != selectedInterval else { return }
        
        selectedInterval = interval
        
        loadTask?.cancel()
        
        loadTask = Task { [weak self] in
            await self?.performLoadCandles(for: interval)
        }
    }
    
    private func performLoadCandles(for interval: CandleInterval) async {
        onLoadingChanged?(true)
        
        defer {
            onLoadingChanged?(false)
        }
        
        do {
            candles = try await dependencies.detailsRepository.candles(for: symbol.name, interval: interval)
            
            onChange?()
        } catch {
            onError?(error)
        }
    }
    
    private func price(_ value: Decimal?) -> String {
        dependencies.processor.price(value, digits: symbol.digits)
    }
    
    private func amount(_ value: Decimal) -> String {
        dependencies.processor.amount(value)
    }
    
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
    
    private func apply(_ quote: MarketQuote) {
        self.quote = quote
        onQuoteChanged?()
    }
}
