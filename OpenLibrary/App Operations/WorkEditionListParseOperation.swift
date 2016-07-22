//  WorkEditionListParseOperation.swift
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
class WorkEditionListParseOperation: Operation {
    
    let parentKey: String
    let cacheFile: NSURL
    
    var editions = [String]()
    
    var searchResults = SearchResults()
    
    /**
        - parameter cacheFile: The file `NSURL` from which to load author query data.
        - parameter context: The `NSManagedObjectContext` that will be used as the
                             basis for importing data. The operation will internally
                             construct a new `NSManagedObjectContext` that points
                             to the same `NSPersistentStoreCoordinator` as the
                             passed-in context.
    */
    init( parentKey: String, cacheFile: NSURL ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.cacheFile = cacheFile
        self.parentKey = parentKey
        
        super.init()

        name = "Parse Work Editions"
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

        let numFound = resultSet.count

        if numFound > 0 {
            for result in resultSet {
                
                if let result = result as? [String: String] {
                    
                    if let editionKey = result["key"] {
                        
                        self.editions.append( editionKey )
                    }
                }
            }
        }

        self.finishWithError( nil )
    }
    
}
