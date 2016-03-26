//  AuthorWorksParseOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation
import CoreData

import BNRCoreDataStack

/// An `Operation` to parse works out of a query from OpenLibrary.
class AuthorWorksParseOperation: Operation {
    
    let authorKey: String
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
    init( authorKey: String, offset: Int, limit: Int, cacheFile: NSURL, coreDataStack: CoreDataStack, updateResults: SearchResultsUpdater ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.cacheFile = cacheFile
        self.context = coreDataStack.newBackgroundWorkerMOC()
        self.context.mergePolicy = NSOverwriteMergePolicy
        self.updateResults = updateResults
        self.offset = offset
        self.limit = limit
        self.authorKey = authorKey
        
        super.init()

        name = "Parse Author Works"
    }
    
    deinit {
        
        print( "\(self.dynamicType.description()) deinit" )
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

        guard var numFound = resultSet["size"] as? Int where numFound > 0 else {
            
            updateResults( SearchResults( start: offset, numFound: offset, pageSize: 0 ) )
            finishWithError( nil )
            return
        }
        
        guard let entries = resultSet["entries"] as? [[String: AnyObject]] else {
            
            updateResults( SearchResults( start: offset, numFound: offset, pageSize: 0 ) )
            finishWithError( nil )
            return
        }
        
        if entries.count < limit {
            numFound = min( numFound, offset + entries.count )
        }

        context.performBlock {
            
            var index = self.offset
            for entry in entries {
                
                if let newObject = OLWorkDetail.parseJSON( "authors", parentKey: self.authorKey, index: index, json: entry, moc: self.context ) {
                
                    index += 1
                    
                    print( "\(newObject.author_key) \(newObject.key) \(newObject.title)" )
                }
            }

            let error = self.saveContext()

            if nil == error {
                self.updateResults( SearchResults( start: self.offset, numFound: numFound, pageSize: entries.count ) )
            }
        
            self.finishWithError( error )
        }
    }
    
//    private func insert( authorKey: String, index: Int, parsed: ParsedSearchResult ) {
//
//        let result = NSEntityDescription.insertNewObjectForEntityForName( OLWorkDetail.entityName, inManagedObjectContext: context ) as! OLWorkDetail
//        
//        result.author_key = "/authors/\(authorKey)"
//        result.index = Int64( index )
//
//        result.key = parsed.key
//        result.created = parsed.created
//        result.last_modified = parsed.last_modified
//        result.revision = parsed.revision
//        result.latest_revision = parsed.latest_revision
//        result.type = parsed.type
//        
//        result.title = parsed.title
//        result.subtitle = parsed.subtitle
//        result.authors = parsed.authors
//        result.translated_titles = parsed.translated_titles
//        result.subjects = parsed.subjects
//        result.subject_places = parsed.subject_places
//        result.subject_times = parsed.subject_times
//        result.subject_people = parsed.subject_people
//        result.work_description = parsed.work_description
//        result.dewey_number = parsed.dewey_number
//        result.lc_classifications = parsed.lc_classifications
//        result.first_sentence = parsed.first_sentence
//        result.original_languages = parsed.original_languages
//        result.other_titles = parsed.other_titles
//        result.first_publish_date = parsed.first_publish_date
//        result.links = parsed.links
//        result.notes = parsed.notes
//        // cover_edition of type /type/edition
//        result.covers = parsed.covers
//        result.coversFound = parsed.covers.count > 0
//    }
    
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
