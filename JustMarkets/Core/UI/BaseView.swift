//
//  BaseView.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import UIKit

class BaseView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)

        initialize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Provides the initialization hook that subclasses must override.
    func initialize() {
        fatalError("BaseView.initialize() must be overridden")
    }
}
