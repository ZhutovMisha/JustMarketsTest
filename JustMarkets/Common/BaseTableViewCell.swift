//
//  BaseTableViewCell.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import UIKit
import UIKit

class BaseTableViewCell: UITableViewCell {

    override init( style: UITableViewCell.CellStyle, reuseIdentifier: String? ) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear

        initialize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initialize() {
        fatalError("initialize() must be overridden")
    }
}
