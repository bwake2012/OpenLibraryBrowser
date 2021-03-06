//  TitleSearchResultsParseOperation.swift
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

let kTitlesPrefix = "/Titles/"

/// A struct to represent a parsed Title search result.

/// An `Operation` to parse earthquakes out of a downloaded feed from the USGS.
class TitleSearchResultsParseOperation: PSOperation {
    
    let cacheFile: URL
    let context: NSManagedObjectContext
    var updateResults: SearchResultsUpdater?
    
    var searchResults = SearchResults()
    
    /**
        - parameter cacheFile: The file `NSURL` from which to load Title query data.
        - parameter context: The `NSManagedObjectContext` that will be used as the
                             basis for importing data. The operation will internally
                             construct a new `NSManagedObjectContext` that points
                             to the same `NSPersistentStoreCoordinator` as the
                             passed-in context.
    */
    init( cacheFile: URL, dataStack: OLDataStack, updateResults: @escaping SearchResultsUpdater ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.cacheFile = cacheFile
        self.context = dataStack.newChildContext( name: "TitleSearchResultsParse Context" )
        self.context.mergePolicy = NSOverwriteMergePolicy
        self.updateResults = updateResults
        
        super.init()

        name = "Parse Title Search Results"
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

        guard let start = resultSet["start"] as? Int else {
            finishWithError( nil )
            return
        }
        
        guard let numFound = resultSet["numFound"] as? Int else {
            finishWithError( nil )
            return
        }
    
        guard let results = resultSet["docs"] as? [[String: AnyObject]] else {
            finishWithError( nil )
            return
        }

        context.perform {
            
            var index = Int64( start )
            for result in results {
                
                if nil != OLTitleSearchResult.parseJSON( 0, index: index, match: result, moc: self.context ) {
                    
                    index += 1
                    
//                    print( "\(newObject.index) \(newObject.title)" )
                }
            }

            let error = self.saveContext()

            if nil == error {
                self.updateResults?(
                        SearchResults( start: Int( start ), numFound: Int( numFound ), pageSize: results.count )
                    )
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
