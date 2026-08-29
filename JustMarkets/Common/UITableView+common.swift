//
//  UITableView+extension.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import UIKit

extension UITableView {
    
    func registerCell<T: UITableViewCell>(_ cellType: T.Type) {
        register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
    }
    
    func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        
        return cell
    }
}
