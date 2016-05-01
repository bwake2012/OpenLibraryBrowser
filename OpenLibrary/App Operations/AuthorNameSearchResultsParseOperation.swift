//  AuthorNameSearchResultsParseOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation
import CoreData

import BNRCoreDataStack

let kAuthorsPrefix = "/authors/"

/// A struct to represent a parsed author search result.
private class ParsedSearchResult: OpenLibraryObject {
    
    // MARK: Properties.

    let sequence: Int64
    let index: Int64
    let key: String
    let name: String
    let birth_date: String
    let death_date: String
    let type: String
    let top_work: String
    let work_count: Int
    
    // MARK: Initialization
    
    init?(
        sequence: Int64,
        index: Int64,
        key: String,
        name: String,
        birth_date: String,
        death_date: String,
        type: String,
        top_work: String,
        work_count: Int
        ) {
            self.sequence = sequence
            self.index = index
            self.key = key
            self.name = name
            self.birth_date = birth_date
            self.death_date = death_date
            self.type = type
            self.top_work = top_work
            self.work_count = work_count
    }
    
    convenience init?( sequence: Int64, index: Int64, match: [String: AnyObject] ) {
        
        guard let key = match["key"] as? String else { return nil }
        
        guard let name = match["name"] as? String else { return nil }
        
        guard let type = match["type"] as? String else { return nil }
        
        let birth_date = OpenLibraryObject.OLDateStamp( match["birth_date"] )
        let death_date = OpenLibraryObject.OLDateStamp( match["death_date"] )
        
        let top_work = match["top_work"] as? String ?? ""
        let work_count = match["work_count"] as? Int ?? 0
        
        self.init( sequence: sequence, index: index, key: key, name: name, birth_date: birth_date, death_date: death_date, type: type, top_work: top_work, work_count: work_count )
        
    }
}

/// An `Operation` to parse author name search results out of a downloaded feed from OpenLibrary.org.
class AuthorNameSearchResultsParseOperation: Operation {
    
    let cacheFile: NSURL
    let context: NSManagedObjectContext
    let updateResults: SearchResultsUpdater
    
    var searchResults = SearchResults()
    
    var authorsFound = [String]()
    
    /**
        - parameter cacheFile: The file `NSURL` from which to load author query data.
        - parameter context: The `NSManagedObjectContext` that will be used as the
                             basis for importing data. The operation will internally
                             construct a new `NSManagedObjectContext` that points
                             to the same `NSPersistentStoreCoordinator` as the
                             passed-in context.
    */
    init( cacheFile: NSURL, coreDataStack: CoreDataStack, updateResults: SearchResultsUpdater ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.cacheFile = cacheFile
        self.context = coreDataStack.newChildContext()
        self.context.mergePolicy = NSOverwriteMergePolicy
        self.updateResults = updateResults
        
        super.init()

        name = "Parse Author Search Results"
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
            finishWithError(jsonError)
        }
    }
    
    private func parse( resultSet: [String: AnyObject] ) {

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

        context.performBlock {
            
            var index = Int64( start )
            for result in results {
                
                if let newResult = ParsedSearchResult( sequence: 0, index: index, match: result ) {
                    
                    self.insert( newResult )
                    index += 1
                    
//                    print( "\(newResult.index) \(newResult.name)" )
                    
                    self.authorsFound.append( newResult.key )
                }
            }

            let error = self.saveContext()

            if nil == error {
                self.updateResults(
                        SearchResults( start: Int( start ), numFound: Int( numFound ), pageSize: results.count )
                    )
            }
        
            self.finishWithError( error )
        }
    }
    
    private func insert( parsed: ParsedSearchResult ) {

        let result = NSEntityDescription.insertNewObjectForEntityForName( OLAuthorSearchResult.entityName, inManagedObjectContext: context) as! OLAuthorSearchResult
        
        result.sequence = parsed.sequence
        result.index = parsed.index
        if parsed.key.hasPrefix( kAuthorsPrefix ) {
            result.key = parsed.key
        } else {
            result.key = kAuthorsPrefix + parsed.key
        }
        result.name = parsed.name
        result.type = parsed.type
        result.birth_date = parsed.birth_date
        result.death_date = parsed.death_date
        result.top_work = parsed.top_work
        result.work_count = Int64( parsed.work_count )
        
        result.havePhoto = HasPhoto.unknown
        result.has_photos = true
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
