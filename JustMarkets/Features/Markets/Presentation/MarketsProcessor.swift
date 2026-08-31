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
    
    /// Creates a market row from symbol metadata, quote data, status, and favorite state.
    /// - Parameters:
    ///   - symbol: The market symbol and display metadata.
    ///   - quote: The current market quote, if available.
    ///   - status: The market status to display.
    ///   - isFavorite: Whether the market is marked as a favorite.
    /// - Returns: A formatted market row.
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
    
    /// Formats an optional price using a digit count appropriate to its magnitude.
    /// - Parameters:
    ///   - price: The price to format.
    ///   - digits: The maximum number of fractional digits for prices less than or equal to 1.
    /// - Returns: The locale-formatted price, or an em dash when the price is missing or cannot be formatted.
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
    
    /// Formats a decimal amount with grouping separators and up to eight fractional digits.
    /// - Parameter value: The amount to format.
    /// - Returns: The formatted amount, or a placeholder when formatting fails.
    func amount(_ value: Decimal) -> String {
        amountFormatter.string(from: value as NSDecimalNumber) ?? Self.placeholder
    }
    
    /// Formats a percentage change for display, using a placeholder when the value is unavailable or cannot be formatted.
    /// - Parameter change: The percentage change to format.
    /// - Returns: The formatted percentage followed by `%`, or `—` when formatting is unavailable.
    func change(_ change: Decimal?) -> String {
        guard
            let change,
            let formatted = changeFormatter.string(from: change as NSDecimalNumber)
        else {
            return Self.placeholder
        }
        
        return formatted + "%"
    }
    
    /// Determines the trend represented by a percentage change.
    /// - Parameter change: The percentage change used to derive the trend.
    /// - Returns: `.flat` for a missing or zero change, `.up` for a positive change, or `.down` for a negative change.
    func trend(_ change: Decimal?) -> MarketRow.Trend {
        guard let change, change != 0 else {
            return .flat
        }
        
        return change > 0 ? .up : .down
    }
}
