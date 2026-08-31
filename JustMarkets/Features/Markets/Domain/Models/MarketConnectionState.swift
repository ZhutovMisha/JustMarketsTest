//
//  MarketConnectionState.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

nonisolated enum MarketConnectionState: Sendable, Equatable {
    
    case connecting
    case connected
    case disconnected
}
