//
//  BaseCollectionViewCell.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import UIKit

class BaseCollectionViewCell: UICollectionViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Performs subclass-specific initialization.
    ///
    /// Subclasses must override this method to provide their initialization logic.
    func initialize() {
        fatalError("initialize() must be overridden")
    }
}
