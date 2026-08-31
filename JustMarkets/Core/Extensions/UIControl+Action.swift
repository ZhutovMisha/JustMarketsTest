//
//  UIControl+Action.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import UIKit

extension UIControl {
    
    typealias ActionHandler = () -> Void
    
    func onTap(_ handler: @escaping ActionHandler) {
        addAction(UIAction { _ in handler() }, for: .touchUpInside)
    }
}
