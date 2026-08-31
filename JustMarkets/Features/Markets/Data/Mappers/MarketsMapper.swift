//
//  MarketsMapper.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation

enum MarketsMapper {
    
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
