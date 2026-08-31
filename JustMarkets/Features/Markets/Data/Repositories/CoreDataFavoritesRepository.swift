//
//  CoreDataFavoritesRepository.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import CoreData

final class CoreDataFavoritesRepository: FavoritesRepository {
    
    private let stack: CoreDataStack
    
    init(stack: CoreDataStack) {
        self.stack = stack
    }
    
    func favorites() throws -> [String] {
        let request = FavoriteSymbolEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \FavoriteSymbolEntity.dateAdded, ascending: false)
        ]
        
        return try stack.viewContext
            .fetch(request)
            .compactMap(\.symbol)
    }
    
    func toggle(_ symbol: String) async throws -> [String] {
        let context = stack.viewContext
        
        let request = FavoriteSymbolEntity.fetchRequest()
        request.predicate = NSPredicate(format: "symbol == %@", symbol)
        
        if let favorite = try context.fetch(request).first {
            context.delete(favorite)
        } else {
            let favorite = FavoriteSymbolEntity(context: context)
            favorite.symbol = symbol
            favorite.dateAdded = Date()
        }
        
        try stack.save()
        
        return try favorites()
    }
}
