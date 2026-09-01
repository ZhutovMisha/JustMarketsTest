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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = viewModel.title
        
        bindViewModel()
        configureIntervalControl()
        
        viewModel.load()
    }
    
    private func bindViewModel() {
        viewModel.onEvent = { [weak self] event in
            guard let self else { return }
            
            switch event {
            case .changed, .quoteChanged:
                render()
                
            case .loading(let isLoading):
                mainView.setAnimating(isLoading)
                
            case .failed(let error):
                showAlert(message: error.localizedDescription)
            }
        }
    }
    
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
    
    private func render() {
        mainView.configure(with: makeConfig())
    }
}

// MARK: - Setup View Config

extension SymbolDetailViewController {
    
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
    
    private func title(for status: MarketStatus) -> String? {
        switch status {
        case .live: nil
        case .closed: "MARKET CLOSED"
        case .noData: "NO DATA"
        case .stale: "STALE QUOTE"
        }
    }
    
    private func color(for trend: MarketRow.Trend) -> UIColor {
        switch trend {
        case .up: Theme.Colors.positive
        case .down: Theme.Colors.negative
        case .flat: Theme.Colors.neutral
        }
    }
}
