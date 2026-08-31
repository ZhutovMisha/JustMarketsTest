//
//  StatusNavigationController.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import UIKit

final class StatusNavigationController: UINavigationController {
    
    enum Status: Equatable {
        
        case normal
        case warning
        case success
    }
    
    private static let successDuration: TimeInterval = 2
    private var status: Status = .normal
    private var resetTask: Task<Void, Never>?
    
    deinit {
        resetTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyStatus()
    }
    
    func setStatus(_ newStatus: Status) {
        guard newStatus != status else { return }
        
        resetTask?.cancel()
        status = newStatus
        
        applyStatus()
        
        guard newStatus == .success else { return }
        
        resetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.successDuration))
            
            guard !Task.isCancelled else { return }
            
            self?.setStatus(.normal)
        }
    }
}

// MARK: - Private

private extension StatusNavigationController {
    
    /// A push or pop already owns the navigation bar: repainting it mid-flight
    /// is what makes the bar flicker, so the status waits for the transition.
    func applyStatus() {
        guard let coordinator = transitionCoordinator else {
            updateAppearance()
            updateRootTitle()
            
            return
        }
        
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.updateAppearance()
            self?.updateRootTitle()
        }
    }
    
    func updateAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        appearance.titleTextAttributes = [
            .foregroundColor: Theme.Colors.primaryText
        ]
        
        navigationBar.tintColor = Theme.Colors.primaryText
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
    }
    
    /// The status replaces the root title only. A pushed screen keeps its own
    /// title — the bar colour is what reports the connection there.
    func updateRootTitle() {
        guard let root = viewControllers.first else { return }
        
        root.navigationItem.title = statusTitle ?? root.title
    }
    
    var statusTitle: String? {
        switch status {
        case .normal:
            nil
            
        case .warning:
            "No connection"
            
        case .success:
            "Connected"
        }
    }
    
    var backgroundColor: UIColor {
        switch status {
        case .normal:
            Theme.Colors.background
            
        case .warning:
            Theme.Colors.errorBackground
            
        case .success:
            Theme.Colors.positive
        }
    }
}
