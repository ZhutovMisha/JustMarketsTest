//
//  Theme.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import UIKit

enum Theme {
    
    enum Colors {
        
        static let background = UIColor.black
        static let primaryText = UIColor.white
        static let secondaryText = UIColor.systemGray
        static let separator = UIColor.systemGray
        static let selectionIndicator = UIColor.white
        static let favorite = UIColor.systemYellow
        static let positive = UIColor.systemGreen
        static let negative = UIColor.systemRed
        static let neutral = UIColor.systemGray
        static let badgeClosed = UIColor.systemRed
        static let badgeNoData = UIColor.systemGray
        static let badgeStale = UIColor.systemOrange
        static let badgeText = UIColor.white
        static let errorBackground = UIColor.systemRed
        static let fieldBackground = UIColor(white: 0.14, alpha: 1)
    }
    
    enum Fonts {
        
        static let segmentTitle = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let rowTitle = UIFont.systemFont(ofSize: 16, weight: .semibold)
        static let rowSubtitle = UIFont.systemFont(ofSize: 13)
        static let badge = UIFont.systemFont(ofSize: 10, weight: .semibold)
        
        static let price = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        static let change = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
    }
    
    enum Spacing {
        
        static let tiny: CGFloat = 2
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
    }
    
    enum Radius {
        
        static let badge: CGFloat = 6
    }
}
