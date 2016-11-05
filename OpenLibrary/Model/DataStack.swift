//
//  OLDataStack.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 10/27/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import PSOperations
import BNRCoreDataStack

fileprivate let storeName = "OpenLibraryBrowser"

protocol OLDataStack: class {
    
    var mainQueueContext: NSManagedObjectContext { get }
    
    init( operationQueue: PSOperationQueue, completion: @escaping () -> Void )
    
    func newChildContext( name: String ) -> NSManagedObjectContext
}

@available(iOS 10.0, *)
class IOS10DataStack: OLDataStack {
    
    fileprivate let persistentContainer = NSPersistentContainer( name: storeName )

    fileprivate var coreDataStack: OLDataStack?
    
    required init( operationQueue: PSOperationQueue, completion: @escaping () -> Void ) {
        
        persistentContainer.loadPersistentStores {
            
            (storeDescription, error ) in

            let delay = DispatchTime.now() + .milliseconds( 250 )
            DispatchQueue.main.asyncAfter( deadline: delay, execute: completion )
        }
    }
    
    var mainQueueContext: NSManagedObjectContext {
        
        let context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    func newChildContext(name: String) -> NSManagedObjectContext {
        
        return persistentContainer.newBackgroundContext()
    }
}

class IOS09DataStack: OLDataStack {

    var mainQueueContext: NSManagedObjectContext {
        
        return self.coreDataStack!.mainQueueContext
    }
    
    var coreDataStack: CoreDataStack?
    
    required init( operationQueue: PSOperationQueue, completion: @escaping () -> Void ) {
        
        CoreDataStack.constructSQLiteStack( modelName: storeName ) {
            
            [weak self] result in
            
            guard let strongSelf = self else { return }
                
            switch result {
                
            case .success(let stack):
                
                strongSelf.coreDataStack = stack
                
                stack.privateQueueContext.performAndWait {
                    stack.privateQueueContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                }
                stack.mainQueueContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                
                let delay = DispatchTime.now() + .milliseconds( 500 )
                DispatchQueue.main.asyncAfter( deadline: delay, execute: completion )
                
            case .failure( let error ):
                assertionFailure("\(error)")
            }
        }
    }
    
    func newChildContext( name: String ) -> NSManagedObjectContext {
        
        return coreDataStack!.newChildContext( name: name )
    }
}
