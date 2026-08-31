//
//  ReusableView.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import UIKit

extension UIView {
    
    static var reuseIdentifier: String {
        String(describing: Self.self)
    }
}
