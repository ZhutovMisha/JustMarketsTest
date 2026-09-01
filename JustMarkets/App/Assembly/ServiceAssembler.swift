//
//  ServiceAssembler.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 01.09.2026.
//

@MainActor
final class ServiceAssembler {
    
    lazy var networkMonitor = NetworkMonitor()
    
    lazy var marketsRepository: MarketsRepository = RemoteMarketsRepository(
        networkClient: networkClient,
        quotesDataSource: MarketsWebSocket(),
        throttle: TickThrottle()
    )
    
    lazy var favoritesRepository: FavoritesRepository = CoreDataFavoritesRepository(stack: coreDataStack)
    
    lazy var symbolDetailsRepository: SymbolDetailsRepository = RemoteSymbolDetailsRepository(
        networkClient: networkClient
    )
    
    private lazy var networkClient: NetworkClient = AFNetworkClient(configuration: configuration)
    
    private lazy var coreDataStack: CoreDataStack = {
        do {
            return try CoreDataStack()
        } catch {
            fatalError("Failed to load the local store: \(error)")
        }
    }()
    
    private let configuration: NetworkConfiguration
    
    init(configuration: NetworkConfiguration = .production) {
        self.configuration = configuration
    }
}
