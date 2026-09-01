//
//  MarketsViewController.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import UIKit

final class MarketsViewController: BaseViewController<MarketsMainView> {
    
    typealias OnSymbolSelected = (MarketSymbol) -> Void
    typealias OnConnectionStateChanged = (MarketConnectionState) -> Void
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, MarketSymbol>
    
    var onSymbolSelected: OnSymbolSelected?
    var onConnectionStateChanged: OnConnectionStateChanged?
    
    private enum Section {
        
        case markets
    }

    private lazy var dataSource: DataSource = {
        DataSource(collectionView: mainView.collectionView) {
            [weak self] collectionView, indexPath, symbol in
            
            let cell: MarketCollectionViewCell =
                collectionView.dequeueReusableCell(for: indexPath)
            
            guard let self else { return cell }
            
            cell.configure(with: viewModel.row(for: symbol), showsSeparator: indexPath.item > 0)
            
            cell.onFavoriteTapped = { [weak self] in
                self?.viewModel.toggleFavorite(for: symbol.name)
            }
            
            return cell
        }
    }()
    
    private let viewModel: MarketsViewModel
    private var pendingSlideDirection: CGFloat?
    
    init(viewModel: MarketsViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Markets"
        
        mainView.collectionView.delegate = self
        mainView.searchBar.delegate = self
        
        bindViewModel()
        configureSegmentControl()
        
        viewModel.loadData()
    }
}

// MARK: - Private

private extension MarketsViewController {
    
    func bindViewModel() {
        viewModel.onEvent = { [weak self] event in
            guard let self else { return }
            
            switch event {
            case .changed:
                applySnapshot()
                
            case .rowsUpdated:
                updateVisibleCells()
                
            case .loading(let isLoading):
                mainView.setAnimating(isLoading)
                
            case .connection(let state):
                onConnectionStateChanged?(state)
                
            case .failed(let error):
                showAlert(message: error.localizedDescription)
            }
        }
    }
    
    func applySnapshot() {
        mainView.setEmptyMessage(viewModel.emptyMessage)
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, MarketSymbol>()
        snapshot.appendSections([.markets])
        snapshot.appendItems(viewModel.visibleSymbols)
        
        let slideDirection = pendingSlideDirection
        pendingSlideDirection = nil
        
        dataSource.apply(snapshot, animatingDifferences: slideDirection == nil) { [weak self] in
            guard  let self, let slideDirection
            else {
                return
            }
            
            mainView.scrollToTop()
            mainView.slideInCollection(direction: slideDirection)
        }
    }
    
    func updateVisibleCells() {
        let collectionView = mainView.collectionView
        
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard
                let symbol = dataSource.itemIdentifier(for: indexPath),
                let cell = collectionView.cellForItem(at: indexPath)
                    as? MarketCollectionViewCell
            else {
                continue
            }
            
            cell.configure(with: viewModel.row(for: symbol), showsSeparator: indexPath.item > 0)
        }
    }
    
    func dismissSearchKeyboard() {
        guard mainView.searchBar.isFirstResponder else { return }
        
        UIView.performWithoutAnimation {
            mainView.searchBar.resignFirstResponder()
            mainView.layoutIfNeeded()
        }
    }
    
    func configureSegmentControl() {
        let categories = viewModel.categories
        
        mainView.segmentControl.configure(
            titles: categories.map(\.rawValue),
            selectedIndex: categories.firstIndex(
                of: viewModel.selectedCategory
            ) ?? 0
        ) { [weak self] index in
            guard
                let self,
                categories.indices.contains(index)
            else {
                return
            }
            
            let category = categories[index]
            
            guard category != viewModel.selectedCategory else {
                return
            }
            
            let currentIndex = categories.firstIndex(of: viewModel.selectedCategory) ?? 0
            
            pendingSlideDirection = index > currentIndex ? 1 : -1
            
            viewModel.selectCategory(category)
        }
    }
}

// MARK: - UISearchBarDelegate

extension MarketsViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.search(searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UICollectionViewDelegate

extension MarketsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        guard let symbol = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        dismissSearchKeyboard()
        
        onSymbolSelected?(symbol)
    }
}
