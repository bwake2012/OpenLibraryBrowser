//  LanguagesParseOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/16/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation
import CoreData

import BNRCoreDataStack

/// An `Operation` to parse works out of a query from OpenLibrary.
class LanguagesParseOperation: Operation {
    
    let offset: Int
    let limit: Int
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
    init( offset: Int, limit: Int, cacheFile: NSURL, coreDataStack: CoreDataStack, updateResults: SearchResultsUpdater ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.cacheFile = cacheFile
        self.context = coreDataStack.newChildContext()
        self.context.mergePolicy = NSOverwriteMergePolicy
        self.updateResults = updateResults
        self.offset = offset
        self.limit = limit
        
        super.init()

        name = "Parse Language Codes"
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
                updateResults( SearchResults( start: offset, numFound: offset, pageSize: 0 ) )
                finish()
            }
        }
        catch let jsonError as NSError {
            finishWithError(jsonError)
        }
    }
    
    private func parse( resultSet: [[String: AnyObject]] ) {

        let numFound = resultSet.count
        if 0 >= numFound {
            
            updateResults( SearchResults( start: offset, numFound: offset, pageSize: 0 ) )
            finishWithError( nil )
            return
        }

        context.performBlock {
            
            let sequence = Int64( 0 )
            var index = Int64( self.offset )
            for entry in resultSet {
                
                if nil != OLLanguage.parseJSON( sequence, index: index, match: entry, moc: self.context ) {
                
                    index += 1
                    
//                    print( "\(newObject.key) \(newObject.code) \(newObject.name)" )
                }
            }

            let error = self.saveContext()

            if nil == error {
                self.updateResults( SearchResults( start: self.offset, numFound: numFound, pageSize: resultSet.count ) )
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
