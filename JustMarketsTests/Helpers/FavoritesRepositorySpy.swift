//
//  FavoritesRepositorySpy.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

@testable import JustMarkets

@MainActor
final class FavoritesRepositorySpy {
    
    enum Message: Equatable {
        
        case favorites
        case toggle(String)
    }
    
    private(set) var messages: [Message] = []
    
    var stored: [String] = []
    
}

// MARK: - FavoritesRepository

extension FavoritesRepositorySpy: FavoritesRepository {
    
    func favorites() throws -> [String] {
        messages.append(.favorites)
        
        return stored
    }
    
    func toggle(_ symbol: String) async throws -> [String] {
        messages.append(.toggle(symbol))
        
        if let index = stored.firstIndex(of: symbol) {
            stored.remove(at: index)
        } else {
            stored.insert(symbol, at: 0)
        }
        
        return stored
    }
}
