//
//  MarketsViewModel.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import Foundation

@MainActor
final class MarketsViewModel {
    
    typealias OnChange = () -> Void
    typealias OnLoadingChanged = (Bool) -> Void
    typealias OnRowsUpdated = () -> Void
    typealias OnConnectionChanged = (MarketConnectionState) -> Void
    typealias OnError = (Error) -> Void
    
    struct Dependencies {
        
        let marketsRepository: MarketsRepository
        let favoritesRepository: FavoritesRepository
        let processor: MarketsProcessor
    }
    
    var onChange: OnChange?
    var onLoadingChanged: OnLoadingChanged?
    var onRowsUpdated: OnRowsUpdated?
    var onConnectionChanged: OnConnectionChanged?
    var onError: OnError?
    
    let categories = MarketCategory.allCases
    
    private(set) var selectedCategory: MarketCategory = .crypto
    private(set) var visibleSymbols: [MarketSymbol] = []
    
    private let dependencies: Dependencies
    private let searchDebounce: Duration
    
    private var symbols: [MarketSymbol] = []
    private var quotes: [String: MarketQuote] = [:]
    private var favorites: [String] = []
    private var query = ""
    private var subscribedNames: [String] = []
    
    private var searchTask: Task<Void, Never>?
    private var updatesTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?
    
    init(dependencies: Dependencies, searchDebounce: Duration = .milliseconds(300)) {
        self.dependencies = dependencies
        self.searchDebounce = searchDebounce
    }
    
    deinit {
        searchTask?.cancel()
        updatesTask?.cancel()
        loadTask?.cancel()
    }
    
    var emptyMessage: String? {
        guard !symbols.isEmpty, visibleSymbols.isEmpty else {
            return nil
        }
        
        if !query.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Nothing found"
        }
        
        if selectedCategory == .favorites {
            return "No favorites yet\nTap the star on a market to add it"
        }
        
        return "No markets in this category"
    }
    
    func row(for symbol: MarketSymbol) -> MarketRow {
        let quote = quotes[symbol.name]
        
        return dependencies.processor.makeRow(
            symbol: symbol,
            quote: quote,
            status: MarketStatus(
                symbol: symbol,
                quote: quote,
                now: .now
            ),
            isFavorite: favorites.contains(symbol.name)
        )
    }
    
    func loadData() {
        loadTask?.cancel()
        
        loadTask = Task { [weak self] in
            guard let self else {
                return
            }
            
            onLoadingChanged?(true)
            
            defer {
                // A newer load already owns the indicator.
                if !Task.isCancelled {
                    onLoadingChanged?(false)
                }
            }
            
            do {
                let loaded = try await dependencies.marketsRepository.fetchSymbols()
                
                // A newer load already owns the state: publishing here would
                // overwrite it and resubscribe to the stale symbol set.
                guard !Task.isCancelled else {
                    return
                }
                
                symbols = loaded
                favorites = try dependencies.favoritesRepository.favorites()
                
                refreshVisibleSymbols()
                onChange?()
                
                resubscribeIfNeeded()
            } catch {
                guard !Task.isCancelled else {
                    return
                }
                
                onError?(error)
            }
        }
    }
    
    func selectCategory(_ category: MarketCategory) {
        guard category != selectedCategory else {
            return
        }
        
        selectedCategory = category
        
        refreshVisibleSymbols()
        onChange?()
        resubscribeIfNeeded()
    }
    
    func search(_ query: String) {
        searchTask?.cancel()
        
        searchTask = Task { [weak self, searchDebounce] in
            try? await Task.sleep(for: searchDebounce)
            
            guard !Task.isCancelled else {
                return
            }
            
            self?.applySearch(query)
        }
    }
    
    func toggleFavorite(for symbol: String) {
        do {
            favorites = try dependencies.favoritesRepository.toggle(symbol)
            
            refreshVisibleSymbols()
            onChange?()
            resubscribeIfNeeded()
        } catch {
            onError?(error)
        }
    }
}

// MARK: - Private

private extension MarketsViewModel {
    
    func applySearch(_ query: String) {
        guard query != self.query else {
            return
        }
        
        self.query = query
        
        refreshVisibleSymbols()
        onChange?()
    }
    
    func refreshVisibleSymbols() {
        visibleSymbols = MarketsFilter.symbols(
            symbols,
            category: selectedCategory,
            favorites: favorites,
            query: query
        )
    }
  
    func resubscribeIfNeeded() {
        let names = MarketsFilter.symbols(
            symbols,
            category: selectedCategory,
            favorites: favorites,
            query: ""
        )
        .map(\.name)
        
        // MarketsFilter pins favourites to the front, so the order changes on
        // every star tap while the set stays the same. Only a different set is
        // worth tearing the stream down for.
        guard Set(names) != Set(subscribedNames) else { return }
        
        subscribedNames = names
        let stream = dependencies.marketsRepository.updates(for: names)
        
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await update in stream {
                self?.apply(update)
            }
        }
    }
    
    func apply(_ update: MarketsUpdate) {
        switch update {
        case .quotes(let quotes):
            for quote in quotes {
                self.quotes[quote.symbol] = quote
            }
            
            onRowsUpdated?()
            
        case .connection(let state):
            onConnectionChanged?(state)
        }
    }
}
