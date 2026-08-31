//
//  SplashMainView.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 31.08.2026.
//

import Lottie
import SnapKit
import UIKit

final class SplashMainView: BaseView {
    
    typealias OnAnimationFinished = () -> Void
    
    private enum Constants {
        
        static let animationName = "trading_market_pulse_lottie"
        static let animationSide: CGFloat = 240
    }
    
    private let animationView: LottieAnimationView = {
        let view = LottieAnimationView(name: Constants.animationName)
        view.contentMode = .scaleAspectFit
        view.loopMode = .playOnce
        view.backgroundBehavior = .pauseAndRestore
        return view
    }()
    
    /// Initializes the view's user interface.
    override func initialize() {
        setupUI()
    }
    
    /// Plays the splash animation and invokes the completion handler when it finishes or is unavailable.
    /// - Parameter finished: The closure called after the animation completes or cannot be played.
    func playAnimation(then finished: @escaping OnAnimationFinished) {
        guard animationView.animation != nil else {
            finished()
            
            return
        }
        
        animationView.play { _ in
            finished()
        }
    }
    
    /// Configures the view background and centers the splash animation at its fixed size.
    private func setupUI() {
        backgroundColor = Theme.Colors.background
        
        addSubview(animationView)
        
        animationView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(Constants.animationSide)
        }
    }
}
