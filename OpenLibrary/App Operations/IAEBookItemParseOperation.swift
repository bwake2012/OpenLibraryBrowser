//  IAEBookItemParseOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation
import CoreData

import BNRCoreDataStack
import PSOperations

/// An `Operation` to parse Editions out of a query from OpenLibrary.
class IAEBookItemParseOperation: PSOperation {
    
    let cacheFile: URL
    let context: NSManagedObjectContext
    
    var searchResults = SearchResults()
    
    /**
        - parameter cacheFile: The file `NSURL` from which to load author query data.
        - parameter context: The `NSManagedObjectContext` that will be used as the
                             basis for importing data. The operation will internally
                             construct a new `NSManagedObjectContext` that points
                             to the same `NSPersistentStoreCoordinator` as the
                             passed-in context.
    */
    init( cacheFile: URL, dataStack: OLDataStack ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.cacheFile = cacheFile
        self.context = dataStack.newChildContext( name: "IAEBookItemParse Context" )
        self.context.mergePolicy = NSOverwriteMergePolicy
        
        super.init()

        name = "Parse IAEBookItem"
    }
    
    override func execute() {
        guard let stream = InputStream(url: cacheFile) else {
            finish()
            return
        }
        
        stream.open()
        
        defer {
            stream.close()
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: stream, options: []) as? [String: AnyObject] {
            
                parse( json )
            }
            else {
                finish()
            }
        }
        catch let jsonError as NSError {
            finishWithError(jsonError)
        }
    }
    
    fileprivate func parse( _ resultSet: [String: AnyObject] ) {

        guard let items = resultSet["items"] as? [[String: AnyObject]] else {
            
            finishWithError( nil )
            return
        }
        
        guard let records = resultSet["records"] as? [String: AnyObject] else {
            
            finishWithError( nil )
            return
        }
        
        guard let firstRecord = records.values.first as? [String: AnyObject] else {
            
            finishWithError( nil )
            return
        }
        
        guard let details = firstRecord["details"] as? [String: AnyObject] else {
            
            finishWithError( nil )
            return
        }
        
        guard 0 < items.count else {
            
            finishWithError( nil )
            return
        }
        
        context.perform {
            
            for (index, jsonItem) in items.enumerated() {
                
                _ = OLEBookItem.parseJSON( jsonItem: jsonItem, jsonDetail: details, moc: self.context )
            }

            let error = self.saveContext()
        
            self.finishWithError( error )
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
            try context.saveContextAndWait()
        }
        catch let saveError as NSError {
            error = saveError
        }

        return error
    }
    
}
