//
//  SymbolDetailViewController.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import UIKit

final class SymbolDetailViewController: BaseViewController<SymbolDetailMainView> {
    
    private let viewModel: SymbolDetailViewModel
    
    init(viewModel: SymbolDetailViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Configures the view controller and begins loading symbol details when its view is loaded.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = viewModel.title
        
        bindViewModel()
        configureIntervalControl()
        
        viewModel.load()
    }
    
    /// Binds view model updates to the view controller's rendering, loading, and error presentation.
    private func bindViewModel() {
        viewModel.onChange = { [weak self] in
            self?.render()
        }
        
        viewModel.onQuoteChanged = { [weak self] in
            self?.render()
        }
        
        viewModel.onLoadingChanged = { [weak self] isLoading in
            self?.mainView.setAnimating(isLoading)
        }
        
        viewModel.onError = { [weak self] error in
            self?.showAlert(message: error.localizedDescription)
        }
    }
    
    /// Configures the interval control with the available intervals and forwards valid selections to the view model.
    private func configureIntervalControl() {
        let intervals = viewModel.intervals
        
        let selectedIndex = intervals.firstIndex(of: viewModel.selectedInterval) ?? 0
        
        mainView.intervalControl.configure(
            titles: intervals.map(\.title),
            selectedIndex: selectedIndex
        ) { [weak self] index in
            guard
                let self,
                intervals.indices.contains(index)
            else {
                return
            }
            
            self.viewModel.selectInterval(intervals[index])
        }
    }
    
    /// Updates the main view to reflect the current symbol details.
    private func render() {
        mainView.configure(with: makeConfig())
    }
}

// MARK: - Setup View Config

extension SymbolDetailViewController {
    
    /// Creates the main view configuration from the current view model state.
    /// - Returns: A configuration containing the symbol details, market status, chart data, quotes, and specifications.
    private func makeConfig() -> SymbolDetailMainView.Config {
        SymbolDetailMainView.Config(
            subtitle: viewModel.subtitle,
            price: viewModel.price,
            change: viewModel.change,
            changeColor: color(for: viewModel.trend),
            status: title(for: viewModel.status),
            interval: viewModel.selectedInterval,
            candles: viewModel.candles,
            quoteRows: viewModel.quoteRows,
            specRows: viewModel.specRows
        )
    }
    
    /// Provides the display text associated with a market status.
    /// - Parameter status: The market status to describe.
    /// - Returns: The corresponding status text, or `nil` when the market is live.
    private func title(for status: MarketStatus) -> String? {
        switch status {
        case .live: nil
        case .closed: "MARKET CLOSED"
        case .noData: "NO DATA"
        case .stale: "STALE QUOTE"
        }
    }
    
    /// Maps a market trend to its corresponding theme color.
    /// - Parameter trend: The market trend to represent.
    /// - Returns: The theme color associated with the trend.
    private func color(for trend: MarketRow.Trend) -> UIColor {
        switch trend {
        case .up: Theme.Colors.positive
        case .down: Theme.Colors.negative
        case .flat: Theme.Colors.neutral
        }
    }
}
