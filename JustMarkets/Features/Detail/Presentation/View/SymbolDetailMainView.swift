//
//  SymbolDetailMainView.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import DGCharts
import UIKit
import SnapKit


final class SymbolDetailMainView: BaseView {
    
    struct Config {
        
        let subtitle: String
        let price: String
        let change: String
        let changeColor: UIColor
        let status: String?
        
        let interval: CandleInterval
        let candles: [MarketCandle]
        
        let quoteRows: [SymbolDetailInfoRow]
        let specRows: [SymbolDetailInfoRow]
    }
    
    let intervalControl = SegmentControl()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.rowSubtitle
        label.textColor = Theme.Colors.secondaryText
        label.numberOfLines = 2
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.badge
        label.textColor = Theme.Colors.badgeStale
        label.isHidden = true
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 32, weight: .semibold)
        label.textColor = Theme.Colors.primaryText
        return label
    }()
    
    private let changeLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.price
        label.textAlignment = .right
        return label
    }()
    
    private let chartView: CandleStickChartView = {
        let view = CandleStickChartView()
        view.legend.enabled = false
        view.rightAxis.enabled = false
        view.chartDescription.enabled = false
        view.doubleTapToZoomEnabled = false
        view.pinchZoomEnabled = true
        
        view.leftAxis.labelTextColor = Theme.Colors.secondaryText
        view.leftAxis.gridColor =
            Theme.Colors.separator.withAlphaComponent(0.2)
        
        view.xAxis.labelPosition = .bottom
        view.xAxis.labelTextColor = Theme.Colors.secondaryText
        view.xAxis.drawGridLinesEnabled = false
        
        view.noDataText = ""
        
        return view
    }()
    
    private let quoteStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Theme.Spacing.medium
        return stackView
    }()
    
    private let specStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Theme.Spacing.medium
        return stackView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Theme.Spacing.extraLarge
        return stackView
    }()
    
    private let scrollView = UIScrollView()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()
    
    override func initialize() {
        setupUI()
    }
    
    func setAnimating(_ isAnimating: Bool) {
        if isAnimating {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    func configure(with config: Config) {
        configureHeader(with: config)
        configureChart(candles: config.candles, interval: config.interval)
        configureRows(config.quoteRows, in: quoteStackView)
        configureRows(config.specRows, in: specStackView)
    }
}

// MARK: - Private

private extension SymbolDetailMainView {
    
    func configureHeader(with config: Config) {
        statusLabel.text = config.status
        statusLabel.isHidden = config.status == nil
        
        subtitleLabel.text = config.subtitle
        priceLabel.text = config.price
        
        changeLabel.text = config.change
        changeLabel.textColor = config.changeColor
    }
    
    func configureChart(candles: [MarketCandle], interval: CandleInterval) {
        guard !candles.isEmpty else {
            chartView.data = nil
            return
        }
        
        let entries = candles.enumerated().map { index, candle in
            CandleChartDataEntry(
                x: Double(index),
                shadowH: candle.high.doubleValue,
                shadowL: candle.low.doubleValue,
                open: candle.open.doubleValue,
                close: candle.close.doubleValue
            )
        }
        
        let dataSet = CandleChartDataSet(entries: entries)
        dataSet.drawValuesEnabled = false
        dataSet.shadowColorSameAsCandle = true
        dataSet.increasingColor = Theme.Colors.positive
        dataSet.increasingFilled = true
        dataSet.decreasingColor = Theme.Colors.negative
        dataSet.decreasingFilled = true
        dataSet.neutralColor = Theme.Colors.neutral
        dataSet.highlightColor = Theme.Colors.primaryText
        
        chartView.xAxis.valueFormatter = CandleDateFormatter(
            dates: candles.map(\.openTime),
            interval: interval
        )
        
        chartView.data = CandleChartData(dataSet: dataSet)
    }
    
    func configureRows(_ rows: [SymbolDetailInfoRow],in stackView: UIStackView) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for row in rows {
            let rowView = SymbolDetailInfoRowView()
            rowView.configure(with: row)
            stackView.addArrangedSubview(rowView)
        }
    }
    
    func setupUI() {
        backgroundColor = Theme.Colors.background
        
        addSubview(scrollView)
        addSubview(activityIndicator)
        
        scrollView.addSubview(contentStackView)
        
        let priceStackView = UIStackView(arrangedSubviews: [priceLabel, changeLabel])
        priceStackView.alignment = .firstBaseline
        
        [
            statusLabel,
            subtitleLabel,
            priceStackView,
            intervalControl,
            chartView,
            quoteStackView,
            specStackView
        ].forEach {
            contentStackView.addArrangedSubview($0)
        }
        
        contentStackView.setCustomSpacing(Theme.Spacing.extraSmall, after: statusLabel)
        contentStackView.setCustomSpacing(Theme.Spacing.extraSmall, after: subtitleLabel)
        
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(safeAreaLayoutGuide)
        }
        
        contentStackView.snp.makeConstraints {
            $0.verticalEdges.equalTo(scrollView.contentLayoutGuide).inset(Theme.Spacing.extraLarge)
            $0.directionalHorizontalEdges.equalTo(scrollView.contentLayoutGuide).inset(Theme.Spacing.extraLarge)
            
            $0.width.equalTo(scrollView.frameLayoutGuide).offset(-Theme.Spacing.extraLarge * 2)
        }
        
        chartView.snp.makeConstraints {
            $0.height.equalTo(240)
        }
        
        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}

// MARK: - Decimal

private extension Decimal {
    
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
