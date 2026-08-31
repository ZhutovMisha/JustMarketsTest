//
//  CoreDataStack.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 30.08.2026.
//

import CoreData

final class CoreDataStack {
    
    private static let modelName = "JustMarketsModel"
    
    private let container: NSPersistentContainer
    
    init(inMemory: Bool = false) throws {
        container = NSPersistentContainer(name: Self.modelName)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
        }
        
        var loadError: Error?
        
        container.loadPersistentStores { _, error in
            loadError = error
        }
        
        if let loadError {
            throw loadError
        }
    }
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    /// Saves changes in the view context.
    /// - Throws: An error if saving the view context fails.
    func save() throws {
        guard viewContext.hasChanges else { return }
        
        try viewContext.save()
    }
}
