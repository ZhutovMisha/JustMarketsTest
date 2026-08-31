//
//  NetworkConfiguration.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import Foundation

struct NetworkConfiguration {
    
    private enum Constants {
        
        static let baseURL = URL(string: "https://biquote.io/api")!
    }

    let baseURL: URL
    let timeoutInterval: TimeInterval
    let decoder: JSONDecoder

    init(
        baseURL: URL,
        timeoutInterval: TimeInterval = 30,
        decoder: JSONDecoder = NetworkConfiguration.makeDefaultDecoder()
    ) {
        self.baseURL = baseURL
        self.timeoutInterval = timeoutInterval
        self.decoder = decoder
    }

    static func makeDefaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static var production: NetworkConfiguration {
        NetworkConfiguration(baseURL: Constants.baseURL)
    }
}
