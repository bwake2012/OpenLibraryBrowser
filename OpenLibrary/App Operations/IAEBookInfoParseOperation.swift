//  InternetArchiveEbookInfoParseOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/16/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation
import CoreData

// import BNRCoreDataStack
import PSOperations

/// An `Operation` to parse works out of a query from OpenLibrary.
class InternetArchiveEbookInfoParseOperation: PSOperation {
    
    let eBookKey:   String
    
    let cacheFile: URL
    let context: NSManagedObjectContext
    
    /**
        - parameter cacheFile: The file `NSURL` from which to load author query data.
        - parameter context: The `NSManagedObjectContext` that will be used as the
                             basis for importing data. The operation will internally
                             construct a new `NSManagedObjectContext` that points
                             to the same `NSPersistentStoreCoordinator` as the
                             passed-in context.
    */
    init( eBookKey: String, cacheFile: URL, dataStack: OLDataStack ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.eBookKey   = eBookKey
       
        self.cacheFile = cacheFile
        self.context = dataStack.newChildContext( name: "InternetArchiveEbookInfoParse Context" )
        self.context.mergePolicy = NSOverwriteMergePolicy

        super.init()

        name = "Parse eBook XML File"
    }

    override func execute() {
        
        context.perform {

            let count = OLEBookFile.parseXML( self.eBookKey, localURL: self.cacheFile, moc: self.context )
 
            if 0 < count {

                let error = self.saveContext()
                
                self.finishWithError( error )
            }
        }
    }
    
        
    /**
        Save the context, if there are any changes.
    
        - returns: An `NSError` if there was an problem saving the `NSManagedObjectContext`,
            otherwise `nil`.
    
        - note: This method returns an `NSError?` because it will be immediately
            passed to the `finishWithError()` method, which accepts an `NSError?`.
    */
    fileprivate func saveContext() -> NSError? {
        var error: NSError?

        do {
            try context.save()
        }
        catch let saveError as NSError {
            error = saveError
        }

        return error
    }
    
}
