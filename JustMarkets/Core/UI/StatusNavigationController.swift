//
//  StatusNavigationController.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import UIKit

final class StatusNavigationController: UINavigationController {
    
    nonisolated enum Status: Equatable {
        
        case normal
        case warning
        case success
    }
    
    private static let successDuration: TimeInterval = 2
    private static let transitionDuration: TimeInterval = 0.25
    private var status: Status = .normal
    private var resetTask: Task<Void, Never>?
    
    deinit {
        resetTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        updateAppearance()
    }
    
    func setStatus(_ newStatus: Status) {
        guard newStatus != status else { return }
        
        resetTask?.cancel()
        status = newStatus
        
        updateAppearance()
        
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
    
    func updateAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        appearance.titleTextAttributes = [
            .foregroundColor: Theme.Colors.primaryText
        ]
        
        navigationBar.tintColor = Theme.Colors.primaryText
        
        UIView.transition(
            with: navigationBar,
            duration: Self.transitionDuration,
            options: [.transitionCrossDissolve, .beginFromCurrentState]
        ) {
            self.navigationBar.standardAppearance = appearance
            self.navigationBar.scrollEdgeAppearance = appearance
            self.updateTitle()
        }
    }
    
    func updateTitle() {
        navigationBar.topItem?.title =
            statusTitle ?? topViewController?.title
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

// MARK: - UINavigationControllerDelegate

extension StatusNavigationController: UINavigationControllerDelegate {
    
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        updateTitle()
    }
}
