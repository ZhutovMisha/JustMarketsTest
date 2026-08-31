//
//  UIControl+Action.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import UIKit

extension UIControl {
    
    typealias ActionHandler = () -> Void
    
    /// Registers a handler to be executed when the control receives a touch-up-inside event.
    /// - Parameter handler: The closure to execute when the control is tapped.
    func onTap(_ handler: @escaping ActionHandler) {
        addAction(UIAction { _ in handler() }, for: .touchUpInside)
    }
}
