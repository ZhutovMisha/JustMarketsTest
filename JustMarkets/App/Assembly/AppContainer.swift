//
//  AppContainer.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

final class AppContainer {
    
    private(set) lazy var networkMonitor = NetworkMonitor()
    
    private let configuration: NetworkConfiguration = .production
    
    private lazy var networkClient: NetworkClient = AFNetworkClient(configuration: configuration)
    
    private lazy var marketsRepository: MarketsRepository = RemoteMarketsRepository(
        networkClient: networkClient,
        quotesDataSource: MarketsWebSocket(),
        throttle: TickThrottle()
    )
    
    private lazy var favoritesRepository: FavoritesRepository = CoreDataFavoritesRepository(stack: coreDataStack)
    
    private lazy var symbolDetailsRepository = RemoteSymbolDetailsRepository(networkClient: networkClient)
    
    private lazy var coreDataStack: CoreDataStack = {
        do {
            return try CoreDataStack()
        } catch {
            fatalError("Failed to load the local store: \(error)")
        }
    }()
    
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
