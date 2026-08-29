//
//  MarketsCell.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//
import UIKit
import SnapKit

final class MarketCell: BaseCollectionViewCell {

    nonisolated struct Config: Hashable {
        
        let symbol: String
        let name: String
        let price: Decimal
        let changePercent: Decimal
    }

    private let symbolLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .white
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .systemGray
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: 16,
            weight: .medium
        )
        label.textColor = .white
        label.textAlignment = .right
        return label
    }()

    private let changeLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: 13,
            weight: .medium
        )
        label.textColor = .systemGray
        label.textAlignment = .right
        return label
    }()

    private let titlesStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4

        stack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stack.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )

        return stack
    }()

    private let quoteStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .trailing
        stack.spacing = 4

        stack.setContentHuggingPriority(.required, for: .horizontal)
        stack.setContentCompressionResistancePriority(
            .required,
            for: .horizontal
        )

        return stack
    }()

    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    // MARK: - Setup
    
    override func prepareForReuse() {
        super.prepareForReuse()
        symbolLabel.text = nil
        nameLabel.text = nil
        priceLabel.text = nil
        changeLabel.text = nil
        separator.isHidden = false
    }

    override func initialize() {
        setupHierarchy()
        setupConstraints()
    }

    private func setupHierarchy() {
        titlesStackView.addArrangedSubview(symbolLabel)
        titlesStackView.addArrangedSubview(nameLabel)

        quoteStackView.addArrangedSubview(priceLabel)
        quoteStackView.addArrangedSubview(changeLabel)

        contentView.addSubview(titlesStackView)
        contentView.addSubview(quoteStackView)
        contentView.addSubview(separator)
    }

    private func setupConstraints() {
        titlesStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(8)
            make.leading.equalToSuperview().offset(16)
        }

        quoteStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(14)
            make.trailing.equalToSuperview().offset(-16)
            make.leading.greaterThanOrEqualTo(titlesStackView.snp.trailing).offset(16)
        }

        separator.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    // MARK: - Configuration

    func configure(with config: Config,showsSeparator: Bool) {
        symbolLabel.text = config.symbol
        nameLabel.text = config.name
        priceLabel.text = config.price.description
        changeLabel.text = config.changePercent.description
        separator.isHidden = !showsSeparator
    }
}
