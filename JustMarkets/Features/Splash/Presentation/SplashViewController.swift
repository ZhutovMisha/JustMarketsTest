//
//  SplashViewController.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 31.08.2026.
//

import UIKit

final class SplashViewController: BaseViewController<SplashMainView> {
    
    typealias OnFinished = () -> Void
    
    var onFinished: OnFinished?
    
    private var hasPlayed = false
    
    /// Starts the splash animation the first time the view appears and invokes the completion callback afterward.
    /// - Parameter animated: Indicates whether the view appearance is animated.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !hasPlayed else { return }
        
        hasPlayed = true
        
        mainView.playAnimation { [weak self] in
            self?.onFinished?()
        }
    }
}
