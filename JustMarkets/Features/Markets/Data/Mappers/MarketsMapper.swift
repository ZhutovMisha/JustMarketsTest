//
//  MarketsMapper.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation

enum MarketsMapper {
    
    /// Converts a market symbol DTO into a market symbol.
    /// - Parameter dto: The market symbol data to convert.
    /// - Returns: A market symbol, or `nil` when the DTO contains an unsupported market type.
    static func map(_ dto: MarketSymbolDTO) -> MarketSymbol? {
        guard let type = MarketType(rawValue: dto.type) else {
            return nil
        }
        
        return MarketSymbol(
            name: dto.name,
            title: dto.description,
            type: type,
            digits: dto.digits,
            isActive: dto.isActive,
            hasData: dto.hasData
        )
    }
    
    /// Converts a market tick data transfer object into a market quote.
    /// - Parameters:
    ///   - dto: The market tick data to map.
    ///   - receivedAt: The timestamp when the tick was received.
    /// - Returns: A market quote populated with the tick's market data.
    static func map(_ dto: MarketTickDTO, receivedAt: Date) -> MarketQuote {
        MarketQuote(
            symbol: dto.symbol,
            price: dto.mid,
            bid: dto.bid,
            ask: dto.ask,
            dayChangePercent: dto.dayDiffPercent,
            updatedAt: receivedAt
        )
    }
}
