//
//  SymbolDetailViewModel.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation

@MainActor
final class SymbolDetailViewModel {
    
    typealias OnEvent = (Event) -> Void
  
    enum Event {
        
        case changed
        case quoteChanged
        case loading(Bool)
        case failed(Error)
    }
    
    struct Dependencies {
        
        let detailsRepository: SymbolDetailsRepository
        let marketsRepository: MarketsRepository
        let processor: MarketsProcessor
    }
    
    var onEvent: OnEvent?
    
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
        onEvent?(.loading(true))
        
        defer {
            // A newer load already owns the indicator.
            if !Task.isCancelled {
                onEvent?(.loading(false))
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
            
            onEvent?(.changed)
            
            observeQuotes()
        } catch {
            guard !Task.isCancelled else { return }
            
            onEvent?(.failed(error))
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
        onEvent?(.loading(true))
        
        defer {
            // A newer load already owns the indicator.
            if !Task.isCancelled {
                onEvent?(.loading(false))
            }
        }
        
        do {
            let loaded = try await dependencies.detailsRepository.candles(for: symbol.name, interval: interval)
            
            guard !Task.isCancelled else { return }
            
            candles = loaded
            
            onEvent?(.changed)
        } catch {
            guard !Task.isCancelled else { return }
            
            onEvent?(.failed(error))
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
        onEvent?(.quoteChanged)
    }
}
