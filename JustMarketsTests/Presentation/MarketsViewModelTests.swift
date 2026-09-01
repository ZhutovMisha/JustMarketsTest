//
//  MarketsViewModelTests.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation
import Testing
@testable import JustMarkets

@MainActor
@Suite
struct MarketsViewModelTests {
    
    @Test
    func loadMarkets_fetchesThenObservesSelectedCategoryOnly() async {
        let (sut, markets, _) = makeSUT()
        markets.symbolsResult = .success([
            makeSymbol("EURUSD", type: .forex),
            makeSymbol("BTCUSD", type: .crypto)
        ])
        sut.selectCategory(.forex)
        
        await loadAndWait(sut)
        
        #expect(markets.messages == [.fetchSymbols, .observeUpdates(["EURUSD"])])
    }
    
    @Test
    func selectCategory_always_replacesVisibleSymbolsAndResubscribes() async {
        let (sut, markets, _) = makeSUT()
        markets.symbolsResult = .success([
            makeSymbol("EURUSD", type: .forex),
            makeSymbol("BTCUSD", type: .crypto)
        ])
        sut.selectCategory(.all)
        
        await loadAndWait(sut)
        
        sut.selectCategory(.crypto)
        
        #expect(sut.visibleSymbols.map(\.name) == ["BTCUSD"])
        await wait { markets.messages.last == .observeUpdates(["BTCUSD"]) }
    }
    
    @Test
    func search_afterDebounce_keepsOnlyMatchingSymbols() async {
        let (sut, markets, _) = makeSUT()
        markets.symbolsResult = .success([makeSymbol("EURUSD"), makeSymbol("GBPUSD")])
        sut.selectCategory(.all)
        
        await loadAndWait(sut)
        
        sut.search("gbp")
        
        await wait { sut.visibleSymbols.map(\.name) == ["GBPUSD"] }
    }
    
    @Test
    func receivedQuote_always_updatesPriceAndNotifiesObserver() async {
        let (sut, markets, _) = makeSUT()
        markets.symbolsResult = .success([makeSymbol("EURUSD", digits: 5)])
        sut.selectCategory(.all)
        
        await loadAndWait(sut)
        
        let events = MarketsEventSpy(sut)
        
        markets.emit(.quotes([makeQuote("EURUSD", price: 1.1, change: -3.01)]))
        
        await wait { events.messages.contains(.rowsUpdated) }
        #expect(sut.row(for: makeSymbol("EURUSD", digits: 5)).price == "1.10")
        #expect(sut.row(for: makeSymbol("EURUSD", digits: 5)).change == "-3.01%")
    }
    
    @Test
    func toggleFavorite_inFavoritesCategory_addsSymbolToVisibleSymbols() async {
        let (sut, markets, favorites) = makeSUT()
        markets.symbolsResult = .success([makeSymbol("EURUSD")])
        sut.selectCategory(.all)
        
        await loadAndWait(sut)
        sut.selectCategory(.favorites)
        
        #expect(sut.visibleSymbols.isEmpty, "Expected no favorites before toggling")
        
        sut.toggleFavorite(for: "EURUSD")
        
        await wait { sut.visibleSymbols.map(\.name) == ["EURUSD"] }
        
        #expect(favorites.messages == [.favorites, .toggle("EURUSD")])
        #expect(sut.row(for: makeSymbol("EURUSD")).isFavorite)
    }
    
    @Test
    func loadMarkets_always_emitsEventsInRenderThenSubscribeOrder() async {
        let (sut, markets, _) = makeSUT()
        markets.symbolsResult = .success([makeSymbol("BTCUSD", type: .crypto)])
        
        let events = MarketsEventSpy(sut)
        
        await loadAndWait(sut)
        
        #expect(events.messages == [.loading(true), .changed, .loading(false)])
        #expect(markets.messages == [.fetchSymbols, .observeUpdates(["BTCUSD"])])
    }
}

// MARK: - Helpers

private extension MarketsViewModelTests {
    
    func makeSUT() -> (
        sut: MarketsViewModel,
        markets: MarketsRepositorySpy,
        favorites: FavoritesRepositorySpy
    ) {
        let markets = MarketsRepositorySpy()
        let favorites = FavoritesRepositorySpy()
        
        let sut = MarketsViewModel(
            dependencies: .init(
                marketsRepository: markets,
                favoritesRepository: favorites,
                processor: MarketsProcessor(locale: Locale(identifier: "en_US_POSIX"))
            ),
            searchDebounce: .zero
        )
        
        return (sut, markets, favorites)
    }
}
