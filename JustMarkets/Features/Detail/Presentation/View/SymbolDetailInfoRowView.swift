//
//  SymbolDetailInfoRowView.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import UIKit
import SnapKit

final class SymbolDetailInfoRowView: BaseView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rowSubtitle
        label.textColor = Theme.Colors.secondaryText
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.change
        label.textColor = Theme.Colors.primaryText
        label.textAlignment = .right
        return label
    }()
    
    /// Sets up the title and value labels with leading and trailing alignment and a minimum spacing between them.
    override func initialize() {
        addSubview(titleLabel)
        addSubview(valueLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.verticalEdges.equalToSuperview()
        }
        
        valueLabel.snp.makeConstraints { make in
            make.trailing.verticalEdges.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(Theme.Spacing.medium)
        }
    }
    
    /// Configures the row with the specified title and value.
    /// - Parameter row: The information row to display.
    func configure(with row: SymbolDetailInfoRow) {
        titleLabel.text = row.title
        valueLabel.text = row.value
    }
}
