//  AuthorEditionsParseOperation.swift
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
class AuthorEditionsParseOperation: Operation {
    
    let authorKey: String
    let offset: Int
    let withCoversOnly: Bool
    let cacheFile: NSURL
    let context: NSManagedObjectContext
    let updateResults: SearchResultsUpdater
    
    var searchResults = SearchResults()
    
    /**
        - parameter cacheFile: The file `NSURL` from which to load author query data.
        - parameter context: The `NSManagedObjectContext` that will be used as the
                             basis for importing data. The operation will internally
                             construct a new `NSManagedObjectContext` that points
                             to the same `NSPersistentStoreCoordinator` as the
                             passed-in context.
    */
    init( authorKey: String, offset: Int, withCoversOnly: Bool, cacheFile: NSURL, coreDataStack: CoreDataStack, updateResults: SearchResultsUpdater ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.cacheFile = cacheFile
        self.context = coreDataStack.newChildContext()
        self.context.mergePolicy = NSOverwriteMergePolicy
        self.updateResults = updateResults
        self.withCoversOnly = withCoversOnly
        self.offset = offset
        self.authorKey = authorKey
        
        super.init()

        name = "Parse Author Editions"
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
            if let json = try NSJSONSerialization.JSONObjectWithStream(stream, options: []) as? [[String: AnyObject]] {
            
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
    
    private func parse( resultSet: [[String: AnyObject]] ) {

        
        // guard let numFound = resultSet["size"] as? Int where numFound > 0 else { return }
        
        let numFound = resultSet.count
        if numFound <= 0 {
            finishWithError( nil )
            return
        }
        
        context.performBlock {
            
            var index = self.offset
            for entry in resultSet {
                
                if let newEdition = OLEditionDetail.parseJSON( self.authorKey, workKey: "", index: index, json: entry, moc: self.context ) {
                    
                    index += 1
                    
//                    print( "\(self.authorKey) \(newEdition.key) \(newEdition.title)" )
                }
            }

            let error = self.saveContext()

            if nil == error {
                self.updateResults( SearchResults( start: self.offset, numFound: numFound, pageSize: resultSet.count ) )
            } else {
                
                print( "\(error?.localizedDescription)" )
            }
        
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
    
    func Update( searchResults: SearchResults ) {
        
        self.searchResults = searchResults
    }
}
