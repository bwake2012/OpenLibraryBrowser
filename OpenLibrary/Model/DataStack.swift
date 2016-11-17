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
fileprivate let appGroupID = "group.net.cockleburr.openlibrary"

func displayAlert( message: String ) {

    NSLog( message + "\n" )
}

func nukeObsoleteStore() -> Void {
    
    if let currentVersion = Bundle.getAppVersionString() {
        
        guard let groupURL = FileManager.default.containerURL( forSecurityApplicationGroupIdentifier: appGroupID ) else {
            
            return
        }
        
        guard let storeFolder = FileManager().urls( for: .documentDirectory, in: .userDomainMask ).first else {
            return
        }
        let versionURL = storeFolder.appendingPathComponent( storeName ).appendingPathExtension( "version" )
        let previousVersion = NSKeyedUnarchiver.unarchiveObject( withFile: versionURL.path ) as? String
        
        if nil == previousVersion || currentVersion != previousVersion {
            
            print( "Nuking previous data store" )
            
            let archiveURL = groupURL.appendingPathComponent( storeName ).appendingPathExtension( "sqlite" )
            
            do {
                /*
                 If we already have a file at this location, just delete it.
                 Also, swallow the error, because we don't really care about it.
                 */
                try FileManager.default.removeItem( at: archiveURL )
                
                let searchStateURL = storeFolder.appendingPathComponent( "SearchState" )
                
                try FileManager.default.removeItem( at: searchStateURL )
            }
            catch {}
            
            let path = versionURL.path
            
            NSKeyedArchiver.archiveRootObject( currentVersion, toFile: path )
        }
    }
}

protocol OLDataStack: class {
    
    var mainQueueContext: NSManagedObjectContext { get }
    
    init( operationQueue: PSOperationQueue, completion: @escaping () -> Void )
    
    func newChildContext( name: String ) -> NSManagedObjectContext
    
    func save() -> Void
}

extension OLDataStack {
    
    func persistentStoreURL() -> URL? {
        
        let groupURL = FileManager.default.containerURL( forSecurityApplicationGroupIdentifier: appGroupID )

        return groupURL?.appendingPathComponent( storeName ).appendingPathExtension( "sqlite" )
    }
}

@available(iOS 10.0, *)
class IOS10DataStack: OLDataStack {
    
    fileprivate let persistentContainer = NSPersistentContainer( name: storeName )

    fileprivate var coreDataStack: OLDataStack?
    
    required init( operationQueue: PSOperationQueue, completion: @escaping () -> Void ) {
        
        guard let storeURL = persistentStoreURL() else {
            
            displayAlert( message: "Unable to create URL to persistent store in app group" )
            fatalError()
        }
        
        persistentContainer.persistentStoreDescriptions.append( NSPersistentStoreDescription( url: storeURL ) )
        persistentContainer.loadPersistentStores {
            
            ( storeDescription, error ) in

            if let error = error as NSError? {
                
                displayAlert( message: "Error \(error), \(error.userInfo) loading persistent store \(storeName)" )
                fatalError()
            }

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
    
    func save () -> Void {
        
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                displayAlert( message: "Unresolved error \(nserror), \(nserror.userInfo)" )
                fatalError()
            }
        }
    }
}

class IOS09DataStack: OLDataStack {

    var mainQueueContext: NSManagedObjectContext {
        
        guard let coreDataStack = self.coreDataStack else {
            
            displayAlert( message: "Error: main context - coreDataStack has not been initialized" )
            fatalError()
        }
        
        return coreDataStack.mainQueueContext
    }
    
    var coreDataStack: CoreDataStack?
    
    required init( operationQueue: PSOperationQueue, completion: @escaping () -> Void ) {
        
        CoreDataStack.constructSQLiteStack( modelName: storeName, at: persistentStoreURL() ) {
            
            [weak self] result in
            
            guard let strongSelf = self else { return }
            
            switch result {
                
            case .success(let stack):
                
                strongSelf.coreDataStack = stack
                
                stack.privateQueueContext.performAndWait {
                    stack.privateQueueContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                }
                stack.mainQueueContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                
                let delay = DispatchTime.now() + .milliseconds( 250 )
                DispatchQueue.main.asyncAfter( deadline: delay, execute: completion )
                
            case .failure( let error ):
                displayAlert( message: "Error \(error) constructing SQLLite stack \(storeName)" )
                fatalError()
            }
        }
    }
    
    func newChildContext( name: String ) -> NSManagedObjectContext {
        
        guard let coreDataStack = self.coreDataStack else {
            
            displayAlert(message: "Error: child context - coreDataStack has not been initialized" )
            fatalError()
        }

        return coreDataStack.newChildContext( name: name )
    }

    func save () -> Void {
        
    }
}
