//
//  MarketsViewControllerTests.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation
import Testing
import UIKit
@testable import JustMarkets

@MainActor
@Suite
struct MarketsViewControllerTests {
    
    @Test
    func viewDidLoad_showsLoadingIndicatorThenRendersSelectedCategory() async {
        let (sut, spy) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        await wait { sut.isShowingLoadingIndicator }
        
        spy.completeLoading(with: [makeSymbol("EURUSD", type: .forex), makeSymbol("BTCUSD", type: .crypto)])
        
        await wait { !sut.isShowingLoadingIndicator }
        await wait { sut.numberOfRenderedMarkets == 1 }
    }
}

// MARK: - Helpers

private extension MarketsViewControllerTests {
    
    func makeSUT() -> (sut: MarketsViewController, spy: MarketsRepositorySpy) {
        let spy = MarketsRepositorySpy()
        let favorites = FavoritesRepositorySpy()
        
        let viewModel = MarketsViewModel(
            dependencies: .init(
                marketsRepository: spy,
                favoritesRepository: favorites,
                processor: MarketsProcessor()
            )
        )
        
        return (MarketsViewController(viewModel: viewModel), spy)
    }
}

// MARK: - MarketsViewController DSL

private extension MarketsViewController {
    
    var isShowingLoadingIndicator: Bool {
        mainView.isAnimating
    }
    
    var numberOfRenderedMarkets: Int {
        guard mainView.collectionView.numberOfSections > 0 else { return 0 }
        
        return mainView.collectionView.numberOfItems(inSection: 0)
    }
}
