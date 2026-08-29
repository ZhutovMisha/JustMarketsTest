//
//  MarketsViewController.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import UIKit

private nonisolated enum MarketsSection: Hashable {
    
    case markets
}

private nonisolated enum Item: Hashable {
    case market(MarketCell.Config)
}

final class MarketsViewController: UIViewController {
    
    private typealias DataSource =
    UICollectionViewDiffableDataSource<MarketsSection, Item>
    
 
    private let mainView = MarketsMainView()
    
    private lazy var dataSource: DataSource = createDataSource()
    private let viewModel: MarketsViewModel
    private var pendingSlideDirection: CGFloat?
    
    init(viewModel: MarketsViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bindViewModel()
        configureSegmentControl()
        
        Task {
            do {
                try await viewModel.loadMarkets()
            } catch {
                print("❌ Failed to load markets:", error)
            }
        }
        
        applySnapshot(animated: false)

    }
    
    private func bindViewModel() {
        viewModel.onChange = { [weak self] in
            self?.applySnapshot(animated: true)
        }
        
        viewModel.onLoadingChanged = { [weak self] isLoading in
            self?.mainView.setAnimating(isLoading)
        }
    }
    
    private func configureSegmentControl() {
        let categories = MarketsViewModel.Category.allCases

        let selectedIndex = categories.firstIndex(of: viewModel.selectedCategory) ?? 0

        mainView.segmentControl.configure(
            titles: categories.map(\.rawValue),
            selectedIndex: selectedIndex
        ) { [weak self] index in
            guard
                let self,
                categories.indices.contains(index)
            else {
                return
            }

            self.selectCategory(categories[index])
        }
    }
    
    private func selectCategory(_ category: MarketsViewModel.Category) {
        guard category != viewModel.selectedCategory else { return }

        let categories = MarketsViewModel.Category.allCases

        guard
            let currentIndex = categories.firstIndex(of: viewModel.selectedCategory),
            let selectedIndex = categories.firstIndex(of: category)
        else {
            return
        }

        pendingSlideDirection = selectedIndex > currentIndex ? 1 : -1

        viewModel.selectCategory(category)
    }
    
    private func createDataSource() -> DataSource {
        DataSource(collectionView: mainView.collectionView) { collectionView, indexPath, item in
            switch item {
            case .market(let config):
                let cell: MarketCell = collectionView.dequeueReusableCell(for: indexPath)
                cell.configure(with: config, showsSeparator: indexPath.item > 0)
                return cell
            }
        }
    }
    
    private func applySnapshot(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<MarketsSection, Item>()
        
        snapshot.appendSections([.markets])
        snapshot.appendItems(viewModel.markets.map(Item.market), toSection: .markets)
        
        guard let direction = pendingSlideDirection else {
            dataSource.apply(snapshot, animatingDifferences: animated)
            return
        }
        
        pendingSlideDirection = nil
        
        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.slideIn(direction: direction)
        }
    }
    
    private func slideIn(direction: CGFloat) {
        let collectionView = mainView.collectionView
        let distance = collectionView.bounds.width * direction

        collectionView.transform = CGAffineTransform(translationX: distance,y: 0)

        UIView.animate(withDuration: 0.35,delay: 0,options: [.curveEaseInOut]) {
            collectionView.transform = .identity
        }
    }
}

// MARK: - UICollectionViewDelegate

extension MarketsViewController: UICollectionViewDelegate {
  
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height
        
        let threshold: CGFloat = 300
        
        guard offsetY + visibleHeight > contentHeight - threshold else { return }
        viewModel.loadMorePages()
    }
}
