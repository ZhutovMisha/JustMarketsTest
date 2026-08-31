//
//  CandleInterval.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

nonisolated enum CandleInterval: String, Sendable, CaseIterable {
    
    case oneMinute = "1m"
    case fiveMinutes = "5m"
    case fifteenMinutes = "15m"
    case thirtyMinutes = "30m"
    case oneHour = "1H"
    case fourHours = "4H"
    case oneDay = "1D"
    
    var title: String {
        rawValue.uppercased()
    }
}
