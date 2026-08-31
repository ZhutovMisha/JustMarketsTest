//
//  MarketsQuotesDataSource.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

@MainActor
protocol MarketsQuotesDataSource: AnyObject {
    
    typealias OnTick = (MarketTickDTO) -> Void
    typealias OnConnectionChanged = (MarketConnectionState) -> Void
    
    var onTick: OnTick? { get set }
    var onConnectionChanged: OnConnectionChanged? { get set }
    
    func connect(symbols: [String])
    func disconnect()
}
