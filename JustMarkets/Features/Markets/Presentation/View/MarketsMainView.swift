//
//  MarketsMainView.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import UIKit
import SnapKit

final class MarketsMainView: BaseView {

    let segmentControl = SegmentControl()
    
    var isAnimating: Bool { activityIndicator.isAnimating }
    
    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .allCharacters
        searchBar.autocorrectionType = .no
        searchBar.keyboardAppearance = .dark
        searchBar.tintColor = Theme.Colors.primaryText
        
        let textField = searchBar.searchTextField
        textField.backgroundColor = Theme.Colors.fieldBackground
        textField.textColor = Theme.Colors.primaryText
        textField.leftView?.tintColor = Theme.Colors.secondaryText
        textField.attributedPlaceholder = NSAttributedString(
            string: "Search",
            attributes: [
                .foregroundColor: Theme.Colors.secondaryText
            ]
        )
        
        return searchBar
    }()
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.keyboardDismissMode = .onDrag
        collectionView.registerCell(MarketCollectionViewCell.self)
        return collectionView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Theme.Spacing.medium
        return stackView
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rowSubtitle
        label.textColor = Theme.Colors.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()
    
    /// Initializes the view's user interface.
    override func initialize() {
        setupUI()
    }
    
    /// Updates the empty-state message and controls the label's visibility.
    /// - Parameter message: The message to display, or `nil` to hide the empty-state label.
    func setEmptyMessage(_ message: String?) {
        emptyStateLabel.text = message
        emptyStateLabel.isHidden = message == nil
    }
    
    /// Scrolls the market collection view to its top content position without animation.
    func scrollToTop() {
        collectionView.setContentOffset(
            CGPoint(x: 0, y: -collectionView.adjustedContentInset.top),
            animated: false
        )
    }
    
    /// Starts or stops the loading activity indicator.
    /// - Parameter isAnimating: Whether the activity indicator should animate.
    func setAnimating(_ isAnimating: Bool) {
        if isAnimating {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    /// Slides the collection view into its resting position from the specified horizontal direction.
    /// - Parameter direction: The horizontal direction and offset multiplier for the initial position.
    func slideInCollection(direction: CGFloat) {
        collectionView.transform = CGAffineTransform(translationX: collectionView.bounds.width * direction, y: 0)
        
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            options: [.curveEaseInOut]
        ) {
            self.collectionView.transform = .identity
        }
    }
    
    /// Configures the view hierarchy, styling, and layout constraints for the market content view.
    private func setupUI() {
        backgroundColor = Theme.Colors.background
        
        addSubview(contentStackView)
        addSubview(emptyStateLabel)
        addSubview(activityIndicator)
        
        contentStackView.addArrangedSubview(searchBar)
        contentStackView.addArrangedSubview(segmentControl)
        contentStackView.addArrangedSubview(collectionView)
        
        contentStackView.setCustomSpacing(0, after: searchBar)
        
        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(Theme.Spacing.medium)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalTo(collectionView)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(collectionView.snp.center)
        }
    }
}

// MARK: - Composition Layout Setup

extension MarketsMainView {
    
    /// Creates the compositional layout for the market collection view.
    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            switch sectionIndex {
            case 0:
                return MarketsMainView.makeMarketsSection()
                
            default:
                return nil
            }
        }
    }
    
    /// Creates the collection view layout section for displaying market items.
    private static func makeMarketsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(64))
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(64)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        return NSCollectionLayoutSection(group: group)
    }
}
