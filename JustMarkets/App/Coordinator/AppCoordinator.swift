//
//  AppCoordinator.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import UIKit

@MainActor
final class AppCoordinator {
    
    private let container: AppContainer
    private let navigationController = StatusNavigationController()
    
    private var isNetworkAvailable = true
    private var isFeedConnected = true
    private var wasDisconnected = false
    
    private var networkTask: Task<Void, Never>?
    
    init(container: AppContainer) {
        self.container = container
        
        observeNetwork(container.networkMonitor)
    }
    
    deinit {
        networkTask?.cancel()
    }
    
    func start() -> UIViewController {
        navigationController.setViewControllers([makeMarkets()], animated: false)
        
        return navigationController
    }
}

// MARK: - Markets

private extension AppCoordinator {
    
    func makeMarkets() -> UIViewController {
        let markets = container.makeMarketsModule()
        
        markets.onSymbolSelected = { [weak self] symbol in
            self?.showDetails(for: symbol)
        }
        
        markets.onConnectionStateChanged = { [weak self] state in
            guard let self else { return }
            
            switch state {
            case .connecting: break
                
            case .connected:
                isFeedConnected = true
                updateStatus()
                
            case .disconnected:
                isFeedConnected = false
                updateStatus()
            }
        }
        
        return markets
    }
    
    func showDetails(for symbol: MarketSymbol) {
        navigationController.pushViewController(
            container.makeSymbolDetailModule(symbol: symbol),
            animated: true
        )
    }
}

// MARK: - Network

private extension AppCoordinator {
    
    func observeNetwork(_ monitor: NetworkMonitor) {
        networkTask = Task { [weak self] in
            for await isConnected in monitor.isConnected() {
                guard let self else { return }
                
                isNetworkAvailable = isConnected
                updateStatus()
            }
        }
    }
    
    func updateStatus() {
        let isConnected = isNetworkAvailable && isFeedConnected
        
        guard isConnected else {
            wasDisconnected = true
            navigationController.setStatus(.warning)
            return
        }
        
        navigationController.setStatus(wasDisconnected ? .success : .normal)
        
        wasDisconnected = false
    }
}
