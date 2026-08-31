//
//  CoreDataFavoritesRepositoryTests.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import Testing
@testable import JustMarkets

@Suite
struct CoreDataFavoritesRepositoryTests {
    
    
    @Test
    func toggle_twice_addsThenRemovesSymbol() async throws {
        let sut = try makeSUT()
        
        let afterAdding = try await sut.toggle("EURUSD")
        let afterRemoving = try await sut.toggle("EURUSD")
        
        #expect(afterAdding == ["EURUSD"])
        #expect(afterRemoving.isEmpty)
    }
    
}

// MARK: - Helpers

private extension CoreDataFavoritesRepositoryTests {
    
    func makeSUT() throws -> FavoritesRepository {
        CoreDataFavoritesRepository(stack: try CoreDataStack(inMemory: true))
    }
}
