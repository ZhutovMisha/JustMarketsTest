//
//  Endpoint.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import Alamofire

protocol Endpoint {

    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders { get }
    var parameters: Parameters? { get }
    var encoding: ParameterEncoding { get }
}

extension Endpoint {

    var method: HTTPMethod { .get }
    var headers: HTTPHeaders { [] }
    var parameters: Parameters? { nil }
    var encoding: ParameterEncoding {
        method == .get ? URLEncoding.queryString : JSONEncoding.default
    }
}
