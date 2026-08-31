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
    
    /// Creates the splash screen module.
    /// - Returns: A configured splash view controller.
    func makeSplashModule() -> SplashViewController {
        SplashViewController()
    }
    
    /// Creates the markets module and its view controller.
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
    
    /// Creates a symbol detail view controller for the specified market symbol.
    /// - Parameter symbol: The market symbol to display.
    /// - Returns: A configured symbol detail view controller.
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
