//
//  BaseViewController.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import UIKit

class BaseViewController<MainView: UIView>: UIViewController {

    let mainView: MainView

    init() {
        mainView = MainView()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = mainView
    }
}
