//
//  MarketsEndpoint.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

enum MarketsEndpoint: Endpoint {

    case symbols

    var path: String {
        switch self {
        case .symbols:
            return "symbols"
        }
    }
}
