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
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value.rounded())
        
        guard dates.indices.contains(index) else { return "" }
        
        return formatter.string(from: dates[index])
    }
}
