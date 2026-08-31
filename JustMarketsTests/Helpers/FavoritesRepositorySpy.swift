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
    
    /// Retrieves the stored favorite symbols.
    /// - Returns: The stored favorite symbols.
    func favorites() throws -> [String] {
        messages.append(.favorites)
        
        return stored
    }
    
    /// Toggles a symbol in the stored favorites.
    /// - Parameter symbol: The symbol to add or remove.
    /// - Returns: The updated list of favorite symbols.
    func toggle(_ symbol: String) throws -> [String] {
        messages.append(.toggle(symbol))
        
        if let index = stored.firstIndex(of: symbol) {
            stored.remove(at: index)
        } else {
            stored.insert(symbol, at: 0)
        }
        
        return stored
    }
}
