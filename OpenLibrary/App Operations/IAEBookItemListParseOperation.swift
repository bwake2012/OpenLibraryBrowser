//  IAEBookItemListParseOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation
import CoreData

import BNRCoreDataStack

/// An `Operation` to parse Editions out of a query from OpenLibrary.
class IAEBookItemListParseOperation: Operation {
    
    let cacheFile: NSURL
    let context: NSManagedObjectContext
    
    let urlString: String
    
    var searchResults = SearchResults()
    
    /**
        - parameter cacheFile: The file `NSURL` from which to load author query data.
        - parameter context: The `NSManagedObjectContext` that will be used as the
                             basis for importing data. The operation will internally
                             construct a new `NSManagedObjectContext` that points
                             to the same `NSPersistentStoreCoordinator` as the
                             passed-in context.
    */
    init( urlString: String, cacheFile: NSURL, coreDataStack: CoreDataStack ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.urlString = urlString
        self.cacheFile = cacheFile
        self.context = coreDataStack.newChildContext()
        self.context.mergePolicy = NSOverwriteMergePolicy
        
        super.init()

        name = "Parse IAEBookItem"
    }
    
    override func execute() {
        guard let stream = NSInputStream(URL: cacheFile) else {
            finish()
            return
        }
        
        stream.open()
        
        defer {
            stream.close()
        }
        
        do {
            if let json = try NSJSONSerialization.JSONObjectWithStream(stream, options: []) as? [String: AnyObject] {
            
                parse( json )
            }
            else {
                finish()
            }
        }
        catch let jsonError as NSError {
            
            print( self.urlString )
            finishWithError(jsonError)
        }
    }
    
    private func parse( resultSet: [String: AnyObject] ) {

        if let resultEntry = resultSet.first {
            
            if let result = resultEntry.1 as? [String: AnyObject] {
        
                guard let items = result["items"] as? [[String: AnyObject]] else {
                    
                    finishWithError( nil )
                    return
                }
                
                guard 0 < items.count else {
                    
                    finishWithError( nil )
                    return
                }
                
                context.performBlock {
                    
                    var index = 0
                    for item in items {
                        
                        let object = OLEBookItem.parseJSON( item, moc: self.context )
                        if nil != object {
                            
//                            print( "\(index): \(object.workKey) \(object.editionKey) \(object.eBookKey)" )
                        
                            index += 1
                        }
                    }

                    let error = self.saveContext()
                    self.finishWithError( error )
                }
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
    private func saveContext() -> NSError? {
        var error: NSError?

        do {
            try context.saveContextAndWait()
        }
        catch let saveError as NSError {
            error = saveError
        }

        return error
    }
    
}
