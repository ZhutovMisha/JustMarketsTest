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
    
    func test_marketsViewController_hasNoLeaks() {
        let markets = MarketsRepositorySpy()
        let favorites = FavoritesRepositorySpy()

        var sut: MarketsViewController? = {
            let viewModel = MarketsViewModel(
                dependencies: .init(
                    marketsRepository: markets,
                    favoritesRepository: favorites,
                    processor: MarketsProcessor()
                )
            )

            return MarketsViewController(viewModel: viewModel)
        }()

        sut?.loadViewIfNeeded()

        trackForMemoryLeaks(sut!)
        trackForMemoryLeaks(markets)
        trackForMemoryLeaks(favorites)

        sut = nil
    }
    
    func test_marketsViewController_isDeallocated() {
        let markets = MarketsRepositorySpy()
        let favorites = FavoritesRepositorySpy()

        weak var weakSUT: MarketsViewController?

        autoreleasepool {
            let viewModel = MarketsViewModel(
                dependencies: .init(
                    marketsRepository: markets,
                    favoritesRepository: favorites,
                    processor: MarketsProcessor()
                )
            )

            let sut = MarketsViewController(viewModel: viewModel)
            weakSUT = sut

            sut.loadViewIfNeeded()
        }

        XCTAssertNil(weakSUT)
    }
}
