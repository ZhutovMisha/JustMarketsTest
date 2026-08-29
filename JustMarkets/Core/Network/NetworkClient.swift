//
//  NetworkClient.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import Alamofire
import Foundation

protocol NetworkClient {
    
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T
}

extension NetworkClient {
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        try await request(endpoint, responseType: T.self)
    }
}

final class AFNetworkClient: NetworkClient {
    
    private let configuration: NetworkConfiguration
    private let session: Session
    
    init(
        configuration: NetworkConfiguration,
        interceptor: RequestInterceptor? = nil
    ) {
        self.configuration = configuration
        
        let sessionConfiguration = URLSessionConfiguration.af.default
        sessionConfiguration.timeoutIntervalForRequest = configuration.timeoutInterval
        
        session = Session(configuration: sessionConfiguration, interceptor: interceptor)
    }
    
    func request<T: Decodable & Sendable>(
        _ endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> T {
        return try await makeRequest(for: endpoint)
            .serializingDecodable(T.self, decoder: configuration.decoder)
            .value
    }
    
    private func makeRequest(for endpoint: Endpoint) -> DataRequest {
        session
            .request(
                configuration.baseURL.appendingPathComponent(endpoint.path),
                method: endpoint.method,
                parameters: endpoint.parameters,
                encoding: endpoint.encoding,
                headers: endpoint.headers
            )
            .validate()
    }
}
