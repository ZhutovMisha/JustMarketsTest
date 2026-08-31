//
//  RemoteSymbolDetailsRepository.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

@MainActor
final class RemoteSymbolDetailsRepository: SymbolDetailsRepository {
    
    private static let candlesLimit = 100
    
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    func details(for symbol: String) async throws -> SymbolDetails {
        let dto = try await networkClient.request(
            MarketDetailsEndpoint.details(symbol: symbol),
            responseType: SymbolDetailsDTO.self
        )
        
        return Self.map(dto)
    }
    
    func candles(for symbol: String, interval: CandleInterval) async throws -> [MarketCandle] {
        let endpoint = MarketDetailsEndpoint.candles(
            symbol: symbol,
            interval: interval,
            limit: Self.candlesLimit
        )
        
        return try await networkClient
            .request(endpoint, responseType: OhlcResponseDTO.self)
            .bars
            .map(Self.map)
            .sorted { $0.openTime < $1.openTime }
    }
}

// MARK: - Mapping

private extension RemoteSymbolDetailsRepository {
    
    static func map(_ dto: SymbolDetailsDTO) -> SymbolDetails {
        SymbolDetails(
            name: dto.name,
            title: dto.description,
            exchange: dto.exchange,
            currency: dto.currency,
            contractSize: dto.contractSize,
            tickSize: dto.tickSize,
            digits: dto.digits,
            isActive: dto.isActive
        )
    }
    
    static func map(_ dto: OhlcResponseDTO.Bar) -> MarketCandle {
        MarketCandle(
            openTime: dto.openTime,
            open: dto.open,
            high: dto.high,
            low: dto.low,
            close: dto.close
        )
    }
}
