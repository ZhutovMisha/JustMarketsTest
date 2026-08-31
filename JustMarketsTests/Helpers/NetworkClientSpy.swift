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
    
    func stub(json: String) {
        result = .success(Data(json.utf8))
    }
}

// MARK: - NetworkClient

extension NetworkClientSpy: NetworkClient {
    
    func request<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T {
        messages.append(.request(path: endpoint.path))
        
        return try NetworkConfiguration.makeDefaultDecoder().decode(T.self, from: try result.get())
    }
}
