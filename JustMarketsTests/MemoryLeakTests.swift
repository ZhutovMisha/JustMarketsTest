//
//  MemoryLeakTests.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 31.08.2026.
//

import Foundation
import XCTest
@testable import JustMarkets

@MainActor
final class MemoryLeakTests: XCTestCase {
    
    func test_marketsViewModel_hasNoLeaks() {
        let markets = MarketsRepositorySpy()
        let favorites = FavoritesRepositorySpy()
        
        let sut = MarketsViewModel(
            dependencies: .init(
                marketsRepository: markets,
                favoritesRepository: favorites,
                processor: MarketsProcessor()
            )
        )
        
        sut.selectCategory(.forex)
        
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(markets)
        trackForMemoryLeaks(favorites)
    }
    
    func test_marketsViewController_hasNoLeaks() {
        let markets = MarketsRepositorySpy()
        let favorites = FavoritesRepositorySpy()
        
        let viewModel = MarketsViewModel(
            dependencies: .init(
                marketsRepository: markets,
                favoritesRepository: favorites,
                processor: MarketsProcessor()
            )
        )
        
        let sut = MarketsViewController(viewModel: viewModel)
        sut.loadViewIfNeeded()
        
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(sut.mainView)
        trackForMemoryLeaks(viewModel)
    }
}
