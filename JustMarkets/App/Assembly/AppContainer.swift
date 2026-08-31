//
//  AppContainer.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

@MainActor
final class AppContainer {
    
    let networkMonitor: NetworkMonitor
    
    private let networkClient: NetworkClient
    private let coreDataStack: CoreDataStack
    private let marketsRepository: MarketsRepository
    private let favoritesRepository: FavoritesRepository
    private let symbolDetailsRepository: RemoteSymbolDetailsRepository
    
    init(configuration: NetworkConfiguration = .production) {
        do {
            coreDataStack = try CoreDataStack()
        } catch {
            fatalError("Failed to load the local store: \(error)")
        }
        
        networkMonitor = NetworkMonitor()
        networkClient = AFNetworkClient(configuration: configuration)
        
        marketsRepository = RemoteMarketsRepository(
            networkClient: networkClient,
            quotesDataSource: MarketsWebSocket(),
            throttle: TickThrottle()
        )
        
        favoritesRepository = CoreDataFavoritesRepository(stack: coreDataStack)
        symbolDetailsRepository = RemoteSymbolDetailsRepository(networkClient: networkClient)
    }
    
    func makeSplashModule() -> SplashViewController {
        SplashViewController()
    }
    
    func makeMarketsModule() -> MarketsViewController {
        let viewModel = MarketsViewModel(
            dependencies: .init(
                marketsRepository: marketsRepository,
                favoritesRepository: favoritesRepository,
                processor: MarketsProcessor()
            )
        )
        
        return MarketsViewController(viewModel: viewModel)
    }
    
    func makeSymbolDetailModule(symbol: MarketSymbol) -> SymbolDetailViewController {
        let viewModel = SymbolDetailViewModel(
            symbol: symbol,
            dependencies: .init(
                detailsRepository: symbolDetailsRepository,
                marketsRepository: marketsRepository,
                processor: MarketsProcessor()
            )
        )
        
        return SymbolDetailViewController(viewModel: viewModel)
    }
}
