//
//  MarketsProcessor.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import Foundation

final class MarketsProcessor {
    
    private static let placeholder = "—"
    
    init(locale: Locale = .current) {
        priceFormatter.locale = locale
        changeFormatter.locale = locale
        amountFormatter.locale = locale
    }
    
    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    private let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        return formatter
    }()
    
    
    private let changeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.positivePrefix = "+"
        return formatter
    }()
    
    func makeRow(
        symbol: MarketSymbol,
        quote: MarketQuote?,
        status: MarketStatus,
        isFavorite: Bool
    ) -> MarketRow {
        MarketRow(
            symbol: symbol.name,
            name: symbol.title,
            price: price(quote?.price, digits: symbol.digits),
            change: change(quote?.dayChangePercent),
            trend: trend(quote?.dayChangePercent),
            status: status,
            isFavorite: isFavorite
        )
    }
    
    func price(_ price: Decimal?, digits: Int) -> String {
        guard let price else {
            return Self.placeholder
        }
        
        let fractionDigits = price > 1
            ? min(digits, 2)
            : digits
        
        priceFormatter.minimumFractionDigits = fractionDigits
        priceFormatter.maximumFractionDigits = fractionDigits
        
        return priceFormatter.string(from: price as NSDecimalNumber)
            ?? Self.placeholder
    }
    
    func amount(_ value: Decimal) -> String {
        amountFormatter.string(from: value as NSDecimalNumber) ?? Self.placeholder
    }
    
    func change(_ change: Decimal?) -> String {
        guard
            let change,
            let formatted = changeFormatter.string(from: change as NSDecimalNumber)
        else {
            return Self.placeholder
        }
        
        return formatted + "%"
    }
    
    func trend(_ change: Decimal?) -> MarketRow.Trend {
        guard let change, change != 0 else {
            return .flat
        }
        
        return change > 0 ? .up : .down
    }
}
