//
//  MarketDetailsEndpoint.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 31.08.2026.
//

import Alamofire

enum MarketDetailsEndpoint: Endpoint {
    
    case details(symbol: String)
    case candles(symbol: String, interval: CandleInterval, limit: Int)
    
    
    var path: String {
        switch self {
        case .details(let symbol):
            "symbols/\(symbol)"
            
        case .candles(let symbol, _, _):
            "\(symbol)/ohlc"
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .details: nil
        case .candles(_, let interval, let limit):
            ["interval": interval.rawValue, "limit": limit]
        }
    }
}
