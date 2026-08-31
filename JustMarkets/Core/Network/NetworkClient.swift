//
//  NetworkClient.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import Alamofire
import Foundation

protocol NetworkClient: Sendable {
    
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T
}

final class AFNetworkClient: NetworkClient {
    
    private let configuration: NetworkConfiguration
    private let session: Session
    
    init(configuration: NetworkConfiguration = .production) {
        self.configuration = configuration
        
        let sessionConfiguration = URLSessionConfiguration.af.default
        sessionConfiguration.timeoutIntervalForRequest = configuration.timeoutInterval
        
        session = Session(configuration: sessionConfiguration)
    }
    
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T {
        try await session
            .request(
                configuration.baseURL.appendingPathComponent(endpoint.path),
                method: endpoint.method,
                parameters: endpoint.parameters,
                encoding: endpoint.encoding,
                headers: endpoint.headers
            )
            .validate()
            .serializingDecodable(T.self, decoder: configuration.decoder)
            .value
    }
}
