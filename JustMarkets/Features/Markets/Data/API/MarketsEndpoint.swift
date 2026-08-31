//
//  MarketsEndpoint.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import Alamofire

enum MarketsEndpoint: Endpoint {
    
    case symbols
    
    var path: String {
        switch self {
        case .symbols: "symbols"
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .symbols: nil
        }
    }
}
