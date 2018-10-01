//  AuthorWorksParseOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation
import CoreData

//import BNRCoreDataStack
import PSOperations

/// An `Operation` to parse works out of a query from OpenLibrary.
class AuthorWorksParseOperation: PSOperation {
    
    let authorKey: String
    let parentObjectID: NSManagedObjectID?
    let offset: Int
    let limit: Int
    let cacheFile: URL
    let context: NSManagedObjectContext
    var updateResults: SearchResultsUpdater?
    
    var searchResults = SearchResults()
    
    /**
        - parameter cacheFile: The file `NSURL` from which to load author query data.
        - parameter context: The `NSManagedObjectContext` that will be used as the
                             basis for importing data. The operation will internally
                             construct a new `NSManagedObjectContext` that points
                             to the same `NSPersistentStoreCoordinator` as the
                             passed-in context.
    */
    init( authorKey: String, parentObjectID: NSManagedObjectID?, offset: Int, limit: Int, cacheFile: URL, dataStack: OLDataStack, updateResults: @escaping SearchResultsUpdater ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.cacheFile = cacheFile
        self.context = dataStack.newChildContext( name: "AuthorWorksParse Context" )
        self.context.mergePolicy = NSOverwriteMergePolicy
        self.updateResults = updateResults
        self.offset = offset
        self.limit = limit
        self.parentObjectID = parentObjectID
        self.authorKey = authorKey
        
        super.init()

        name = "Parse Author Works"
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

        guard var numFound = resultSet["size"] as? Int else {
            
            updateResults?( SearchResults( start: offset, numFound: offset, pageSize: 0 ) )
            finishWithError( nil )
            return
        }
        
        guard let entries = resultSet["entries"] as? [[String: AnyObject]] else {
            
            updateResults?( SearchResults( start: offset, numFound: offset, pageSize: 0 ) )
            finishWithError( nil )
            return
        }

        let pageSizeReturned = entries.count
        
        if 0 == numFound {
            
            numFound = offset + pageSizeReturned
        }
            
        if 0 == numFound {

            updateResults?( SearchResults( start: offset, numFound: offset, pageSize: 0 ) )
            finishWithError( nil )
            return
        }
        
        if entries.count < limit {
            numFound = min( numFound, offset + entries.count )
        }

        context.perform {
            
            var index = self.offset
            
            for entry in entries {
                
                if nil != OLWorkDetail.parseJSON( self.authorKey, index: index, currentObjectID: nil, json: entry, moc: self.context ) {
                
                    index += 1
                }
            }
        
            let error = self.saveContext()

            if nil == error {
                self.updateResults?( SearchResults( start: self.offset, numFound: numFound, pageSize: entries.count ) )
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
    
    func Update( _ searchResults: SearchResults ) {
        
        self.searchResults = searchResults
    }
}
