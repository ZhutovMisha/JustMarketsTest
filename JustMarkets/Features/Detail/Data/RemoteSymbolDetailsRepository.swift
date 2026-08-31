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
    
    /// Retrieves detailed market information for a symbol.
    /// - Parameter symbol: The symbol whose market details should be retrieved.
    /// - Returns: The market details for the symbol.
    func details(for symbol: String) async throws -> SymbolDetails {
        let dto = try await networkClient.request(
            MarketDetailsEndpoint.details(symbol: symbol),
            responseType: SymbolDetailsDTO.self
        )
        
        return Self.map(dto)
    }
    
    /// Retrieves candle data for a symbol and interval in ascending opening-time order.
    /// - Parameters:
    ///   - symbol: The symbol whose candle data is requested.
    ///   - interval: The interval represented by each candle.
    /// - Returns: Up to 100 candles sorted by ascending opening time.
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
    
    /// Converts symbol details data into the corresponding domain model.
    — Returns: The mapped symbol details.
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
    
    /// Converts an OHLC bar response into a market candle.
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
