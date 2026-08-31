//
//  Untitled.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import UIKit

extension UIViewController {

    /// Presents an alert with the specified title and message.
    /// - Parameters:
    ///   - title: The alert title. Defaults to `"Error"`.
    ///   - message: The message displayed in the alert.
    func showAlert(title: String = "Error", message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))

        present(alert, animated: true)
    }
}
