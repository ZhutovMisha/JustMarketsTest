//
//  MarketsViewModel.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import Foundation

@MainActor
final class MarketsViewModel {

    enum Category: String, CaseIterable {
        
        case all = "All"
        case favorites = "Favorites"
        case forex = "Forex"
        case crypto = "Crypto"
        case stocks = "Stocks"
        case indices = "Indices"
        case commodities = "Commodities"
        case futures = "Futures"
    }

    private let networkClient: NetworkClient

    var onChange: (() -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?

    private(set) var allMarkets: [MarketCell.Config] = []
    private(set) var markets: [MarketCell.Config] = []
    private(set) var selectedCategory: Category = .forex
    
    private let pageSize = 20
    private var currentPage = 0

    private var symbols: [MarketSymbolDTO] = []

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func loadMarkets() async throws {
        onLoadingChanged?(true)

        defer {
            onLoadingChanged?(false)
        }

        symbols = try await networkClient.request(
            MarketsEndpoint.symbols,
            responseType: [MarketSymbolDTO].self
        )

        updateMarkets()
        onChange?()
    }
    
    
     func loadMorePages() {
        let nextPage = currentPage + 1
        let startIndex = nextPage * pageSize
        
        guard startIndex < allMarkets.count else { return }
        
        let endIndex = min(startIndex + pageSize, allMarkets.count)
        markets.append(contentsOf: allMarkets[startIndex..<endIndex])
        
        currentPage = nextPage
        onChange?()
    }

    func selectCategory(_ category: Category) {
        guard category != selectedCategory else {
            return
        }

        selectedCategory = category
        updateMarkets()
        onChange?()
    }

    private func updateMarkets() {
        allMarkets = symbols
            .filter { matchesCategory($0) }
            .map {
                MarketCell.Config(
                    symbol: $0.name,
                    name: $0.description,
                    price: $0.tickValue,
                    changePercent: $0.contractSize
                )
            }
        
        currentPage = 0
        markets = Array(allMarkets.prefix(pageSize))
    }


    private func matchesCategory( _ symbol: MarketSymbolDTO) -> Bool {
        switch selectedCategory {
        case .all:
             false
        case .favorites:
             false
        case .forex:
            symbol.type == .forex
        case .crypto:
            symbol.type == .crypto
        case .stocks:
            symbol.type == .stock
        case .indices:
            symbol.type == .index
        case .commodities:
            symbol.type == .commodity
        case .futures:
            symbol.type == .future
        }
    }
}
