//
//  NetworkClientSpy.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Foundation
@testable import JustMarkets

@MainActor
final class NetworkClientSpy {
    
    enum Message: Equatable {
        
        case request(path: String)
    }
    
    private(set) var messages: [Message] = []
    
    var result: Result<Data, Error> = .success(Data("[]".utf8))
    
    /// Configures the client to return the specified JSON string as response data.
    /// - Parameter json: The JSON string to use as the response.
    func stub(json: String) {
        result = .success(Data(json.utf8))
    }
}

// MARK: - NetworkClient

extension NetworkClientSpy: NetworkClient {
    
    /// Requests an endpoint and decodes its response into the specified type.
    /// - Parameters:
    ///   - endpoint: The endpoint to request.
    ///   - responseType: The type used to decode the response.
    /// - Returns: The decoded response.
    func request<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T {
        messages.append(.request(path: endpoint.path))
        
        return try NetworkConfiguration.makeDefaultDecoder().decode(T.self, from: try result.get())
    }
}
