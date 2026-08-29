//
//  MarketsViewController.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import UIKit

final class MarketsViewController: UIViewController {
    
    private let mainView = MarketsMainView()
    
    override func loadView() {
        view = mainView
    }
}
