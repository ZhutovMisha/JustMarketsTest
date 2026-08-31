//
//  MarketCollectionViewCell.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//
import UIKit
import SnapKit

final class MarketCollectionViewCell: BaseCollectionViewCell {
    
    typealias OnFavoriteTapped = () -> Void
    
    private static let favoriteImage = UIImage(systemName: "star.fill")
    private static let notFavoriteImage = UIImage(systemName: "star")
    
    private let symbolLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rowTitle
        label.lineBreakMode = .byTruncatingTail
        label.textColor = Theme.Colors.primaryText
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rowSubtitle
        label.textColor = Theme.Colors.secondaryText
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.price
        label.textColor = Theme.Colors.primaryText
        label.textAlignment = .right
        return label
    }()
    
    private let changeLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.change
        label.textColor = Theme.Colors.secondaryText
        label.textAlignment = .right
        return label
    }()
    
    private let titlesStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = Theme.Spacing.extraSmall
        stack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return stack
    }()
    
    private let quoteStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .trailing
        stack.spacing = Theme.Spacing.extraSmall
        stack.setContentCompressionResistancePriority(.required, for: .horizontal)
        return stack
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.badge
        label.textColor = Theme.Colors.badgeText
        return label
    }()
    
    private let statusBadge: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Theme.Radius.badge
        view.isHidden = true
        return view
    }()
    
    private let symbolStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Theme.Spacing.small
        return stack
    }()
    
    private let favoriteButton: UIButton = {
        let button = UIButton()
        
        button.setImage(UIImage(systemName: "star")?.withRenderingMode(.alwaysOriginal).withTintColor(Theme.Colors.favorite), for: .normal)
        button.setImage(UIImage(systemName: "star.fill")?.withRenderingMode(.alwaysOriginal).withTintColor(Theme.Colors.favorite), for: .selected)
        
        return button
    }()
    
    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.separator
        return view
    }()
    
    // MARK: - Setup
    
    var onFavoriteTapped: OnFavoriteTapped?
    
    override func prepareForReuse() {
        super.prepareForReuse()

        onFavoriteTapped = nil
        priceLabel.layer.removeAllAnimations()
    }
    
    override func initialize() {
        setupHierarchy()
        setupConstraints()
    }
    
    private func setupHierarchy() {
        statusBadge.addSubview(statusLabel)
        
        symbolStackView.addArrangedSubview(symbolLabel)
        symbolStackView.addArrangedSubview(statusBadge)
        
        titlesStackView.addArrangedSubview(symbolStackView)
        titlesStackView.addArrangedSubview(nameLabel)
        
        quoteStackView.addArrangedSubview(priceLabel)
        quoteStackView.addArrangedSubview(changeLabel)
        
        contentView.addSubview(favoriteButton)
        contentView.addSubview(titlesStackView)
        contentView.addSubview(quoteStackView)
        
        favoriteButton.onTap { [weak self] in
            self?.onFavoriteTapped?()
        }
        contentView.addSubview(separator)
    }
    
    private func setupConstraints() {
        favoriteButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Theme.Spacing.extraLarge)
            make.size.equalTo(28)
        }
        
        titlesStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(Theme.Spacing.medium)
            make.leading.equalTo(favoriteButton.snp.trailing).offset(Theme.Spacing.large)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(Theme.Spacing.tiny)
            make.horizontalEdges.equalToSuperview().inset(Theme.Spacing.small)
        }
        
        quoteStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(Theme.Spacing.large)
            make.trailing.equalToSuperview().offset(-Theme.Spacing.extraLarge)
            make.width.equalTo(100).priority(999)
            make.leading.greaterThanOrEqualTo(titlesStackView.snp.trailing)
                .offset(Theme.Spacing.large)
        }
        
        separator.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Theme.Spacing.extraLarge)
            make.top.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    // MARK: - Configuration
    
    func configure(with row: MarketRow, showsSeparator: Bool) {
        symbolLabel.text = row.symbol
        nameLabel.text = row.name
        changeLabel.text = row.change
        changeLabel.textColor = color(for: row.trend)
        configureStatus(row.status)
        favoriteButton.isSelected = row.isFavorite
        separator.isHidden = !showsSeparator
        
        guard priceLabel.text != row.price else { return }
        
        updatePrice(row.price)
    }
    
    private func configureStatus(_ status: MarketStatus) {
        statusBadge.isHidden = status == .live
        
        switch status {
        case .live:
            break
            
        case .closed:
            statusLabel.text = "CLOSED"
            statusBadge.backgroundColor = Theme.Colors.badgeClosed
            
        case .noData:
            statusLabel.text = "NO DATA"
            statusBadge.backgroundColor = Theme.Colors.badgeNoData
            
        case .stale:
            statusLabel.text = "STALE"
            statusBadge.backgroundColor = Theme.Colors.badgeStale
        }
    }
    
    private func color(for trend: MarketRow.Trend) -> UIColor {
        switch trend {
        case .up: Theme.Colors.positive
        case .down: Theme.Colors.negative
        case .flat: Theme.Colors.neutral
        }
    }
    
    private func updatePrice(_ text: String) {
        let transition = CATransition()
        transition.type = .fade
        transition.duration = 0.2
        
        priceLabel.layer.add(transition, forKey: "priceUpdate")
        priceLabel.text = text
    }
}
