//
//  CandleDateFormatter.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import DGCharts
import Foundation

final class CandleDateFormatter: NSObject, AxisValueFormatter {
    
    private let dates: [Date]
    private let formatter: DateFormatter
    
    init(dates: [Date], interval: CandleInterval) {
        self.dates = dates
        
        let formatter = DateFormatter()
        formatter.dateFormat = interval == .oneDay ? "dd MMM" : "HH:mm"
        
        self.formatter = formatter
        
        super.init()
    }
    
    /// Formats the date at the axis value's nearest candle index.
    /// - Parameter value: The axis value used to select a date.
    /// - Returns: The formatted date, or an empty string when the index is outside the available dates.
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value.rounded())
        
        guard dates.indices.contains(index) else { return "" }
        
        return formatter.string(from: dates[index])
    }
}
