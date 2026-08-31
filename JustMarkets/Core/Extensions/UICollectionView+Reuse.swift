//
//  UICollectionView+extension.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import UIKit

extension UICollectionView {
    
    /// Registers a collection view cell type using its reuse identifier.
    /// - Parameter type: The cell type to register.
    func registerCell<T: UICollectionViewCell>(_: T.Type) {
        register(T.self, forCellWithReuseIdentifier: T.reuseIdentifier)
    }
    
    /// Dequeues and returns a reusable cell of the requested type for the specified index path.
    /// - Parameter indexPath: The index path identifying the cell.
    /// - Returns: The dequeued cell cast to the requested type.
    /// - Note: Terminates execution if the dequeued cell cannot be cast to the requested type.
    func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        
        return cell
    }
}
