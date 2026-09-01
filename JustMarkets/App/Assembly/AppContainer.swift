//
//  AppContainer.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

@MainActor
final class AppContainer {
    
    lazy var services = ServiceAssembler(configuration: configuration)
    
    private let configuration: NetworkConfiguration
    
    init(configuration: NetworkConfiguration = .production) {
        self.configuration = configuration
    }
    
    func makeSplashModule() -> SplashViewController {
        SplashViewController()
    }
    
    func makeMarketsModule() -> MarketsViewController {
        let viewModel = MarketsViewModel(
            dependencies: .init(
                marketsRepository: services.marketsRepository,
                favoritesRepository: services.favoritesRepository,
                processor: MarketsProcessor()
            )
        )
        
        return MarketsViewController(viewModel: viewModel)
    }
    
    func makeSymbolDetailModule(symbol: MarketSymbol) -> SymbolDetailViewController {
        let viewModel = SymbolDetailViewModel(
            symbol: symbol,
            dependencies: .init(
                detailsRepository: services.symbolDetailsRepository,
                marketsRepository: services.marketsRepository,
                processor: MarketsProcessor()
            )
        )
        
        return SymbolDetailViewController(viewModel: viewModel)
    }
}
