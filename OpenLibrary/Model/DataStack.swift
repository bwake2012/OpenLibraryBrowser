//
//  OLDataStack.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 10/27/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import PSOperations
//import BNRCoreDataStack

fileprivate let storeName = "OpenLibraryBrowser"
fileprivate let appGroupID = "group.net.cockleburr.openlibrary"

func nukeObsoleteStore() -> Void {
    
    if let currentVersion = Bundle.getAppVersionString() {
        
        guard let groupURL = FileManager.default.containerURL( forSecurityApplicationGroupIdentifier: appGroupID ) else {
            
            return
        }
        
        guard let storeFolderURL = FileManager().urls( for: .documentDirectory, in: .userDomainMask ).first else {
            return
        }

        let versionURL = storeFolderURL.appendingPathComponent( storeName ).appendingPathExtension( "version" )
        guard
            let data = try? Data(contentsOf: versionURL),
            let version = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSString.self, from: data)
        else {
            return
        }

        let previousVersion = version as String
        if currentVersion != previousVersion {
            
            NSLog( "Nuking previous data store" )
            
            let archiveURL = groupURL.appendingPathComponent( storeName ).appendingPathExtension( "sqlite" )
            do {
                /*
                 If we already have a file at this location, just delete it.
                 Also, swallow the error, because we don't really care about it.
                 */
                
                try FileManager.default.removeItem( at: archiveURL )
            }
            catch {
                
                NSLog( "Error \(error) removing \(archiveURL)" )
            }
            
            let searchStateURL = storeFolderURL.appendingPathComponent( "SearchState" )
            do {
                
                try FileManager.default.removeItem( at: searchStateURL )
            }
            catch {
                
                NSLog( "Error \(error) removing \(searchStateURL)" )
            }

            let oldArchiveURL = storeFolderURL.appendingPathComponent( storeName ).appendingPathExtension( "sqlite" )
            do {
            
                try FileManager.default.removeItem( at: oldArchiveURL )
            }
            catch {
            
                NSLog( "Error \(error) removing \(oldArchiveURL)" )
            }
            
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: currentVersion, requiringSecureCoding: true) {

                try? data.write(to: versionURL)
            }
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

        let url = groupURL?.appendingPathComponent( storeName ).appendingPathExtension( "sqlite" )
        
        // NSLog( "persistentStoreURL: \(url?.description)" )
        
        return url
    }
}

@available(iOS 10.0, *)
class OLPersistentContainer: NSPersistentContainer {
    
    override class func defaultDirectoryURL() -> URL {
        
        return FileManager.default.containerURL( forSecurityApplicationGroupIdentifier: appGroupID )!
    }
}

@available(iOS 10.0, *)
class IOS10DataStack: OLDataStack {
    
    fileprivate let persistentContainer = OLPersistentContainer( name: storeName )

    fileprivate var dataStack: OLDataStack?
    
    required init( operationQueue: PSOperationQueue, completion: @escaping () -> Void ) {
        
        persistentContainer.loadPersistentStores {
            
            ( storeDescription, error ) in

            if let error = error as NSError? {
                
                fatalError( "Error \(error), \(error.userInfo) loading persistent store \(storeName)" )
            }

            // NSLog( "persistent store loaded" )
            let delay = DispatchTime.now() + .milliseconds( 250 )
            DispatchQueue.main.asyncAfter( deadline: delay, execute: completion )
        }
    }
    
    var mainQueueContext: NSManagedObjectContext {
        
        // NSLog( "retrieve mainQueueContext \(Thread.isMainThread ? "Main" : "Background")" )
        let context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    func newChildContext(name: String) -> NSManagedObjectContext {
        
        // NSLog( "retrieve newChildContext \(name)" )
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
                fatalError( "Unresolved error \(nserror), \(nserror.userInfo)" )
            }
        }
    }
}
