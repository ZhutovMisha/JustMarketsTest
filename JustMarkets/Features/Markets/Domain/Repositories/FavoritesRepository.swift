//
//  FavoritesRepository.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

protocol FavoritesRepository {
    
    func favorites() throws -> [String]
    func toggle(_ symbol: String) throws -> [String]
}
