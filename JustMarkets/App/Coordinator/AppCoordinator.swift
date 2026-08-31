//
//  AppCoordinator.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import UIKit

@MainActor
final class AppCoordinator {
    
    private static let rootTransitionDuration: TimeInterval = 0.3
    
    private let container: AppContainer
    private let navigationController = StatusNavigationController()
    
    private weak var window: UIWindow?
    
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
    
    /// Starts the application by displaying the splash screen and transitioning to the markets flow when it finishes.
    /// - Parameter window: The window in which to display the application interface.
    func start(in window: UIWindow) {
        self.window = window
        
        let splash = container.makeSplashModule()
        
        splash.onFinished = { [weak self] in
            self?.showMarkets()
        }
        
        window.rootViewController = splash
    }
}

// MARK: - Markets

private extension AppCoordinator {
    
    /// Displays the markets module as the application’s root view.
    func showMarkets() {
        guard let window else { return }
        
        navigationController.setViewControllers([makeMarkets()], animated: false)
        
        UIView.transition(
            with: window,
            duration: Self.rootTransitionDuration,
            options: [.transitionCrossDissolve]
        ) {
            window.rootViewController = self.navigationController
        }
    }
    
    /// Creates the markets view controller and configures symbol selection and feed connection state handling.
    /// - Returns: The markets view controller.
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
    
    /// Displays the details screen for the specified market symbol.
    /// - Parameter symbol: The market symbol whose details should be displayed.
    func showDetails(for symbol: MarketSymbol) {
        navigationController.pushViewController(
            container.makeSymbolDetailModule(symbol: symbol),
            animated: true
        )
    }
}

// MARK: - Network

private extension AppCoordinator {
    
    /// Observes network connectivity changes and updates the application status accordingly.
    /// - Parameter monitor: The monitor that provides network connectivity updates.
    func observeNetwork(_ monitor: NetworkMonitor) {
        networkTask = Task { [weak self] in
            for await isConnected in monitor.isConnected() {
                guard let self else { return }
                
                isNetworkAvailable = isConnected
                updateStatus()
            }
        }
    }
    
    /// Updates the navigation status based on network and feed connectivity, indicating connection loss, recovery, or normal availability.
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
