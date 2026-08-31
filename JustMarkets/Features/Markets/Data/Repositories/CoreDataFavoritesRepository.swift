//
//  CoreDataFavoritesRepository.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import CoreData

@MainActor
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
    
    func toggle(_ symbol: String) throws -> [String] {
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
        
        do {
            try stack.save()
        } catch {
            // Otherwise the change stays pending in the view context: later
            // reads see it, and the next successful save commits it silently.
            context.rollback()
            
            throw error
        }
        
        return try favorites()
    }
}
