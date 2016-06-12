//  WorkDetailParseOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/2/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation
import CoreData

import BNRCoreDataStack

/// A struct to represent a parsed Work search result.
private class ParsedSearchResult: OpenLibraryObject {
    
    // MARK: Properties.

    let key: String
    let name: String
    let personal_name: String
    let birth_date: String
    let death_date: String
    
    let photos: [Int]                // transformable
    let links: [[String: String]]    // transformable
    let bio: String
    let alternate_names: [String]    // transformable
    
    let wikipedia: String
    
    let revision: Int64
    let latest_revision: Int64
    
    let created: NSDate?
    let last_modified: NSDate?
    
    let type: String
    
    // MARK: Class Factory
    
    class func fromJSON ( match: [String: AnyObject] ) -> ParsedSearchResult? {
        
        guard let key = match["key"] as? String else { return nil }
        
        guard let name = match["name"] as? String else { return nil }
        
        let personal_name = match["personal_name"] as? String ?? ""
        
        let birth_date = OpenLibraryObject.OLDateStamp( match["birth_date"] )
        let death_date = OpenLibraryObject.OLDateStamp( match["death_date"] )
        
        let photos = OpenLibraryObject.OLIntArray( match["photos"] )

        let links = OpenLibraryObject.OLLinks( match )
        
        let bioText = OpenLibraryObject.OLText( match["bio"] )
        
        let alternate_names = OpenLibraryObject.OLStringArray( match["alternate_names"] )
        
        let wikipedia = OpenLibraryObject.OLString( match["wikipedia"] )
        
        var revision = Int64( 0 )
        if let r = match["revision"] as? Int64 {
            
            revision = r
        }

        var latest_revision = Int64( 0 )
        if let lr = match["latest_revision"] as? Int64 {
            
            latest_revision = lr
        }
        
        let created = OpenLibraryObject.OLTimeStamp( match["created"] )
        
        let last_modified = OpenLibraryObject.OLTimeStamp( match["last_modified"] )
        
        let type = match["type"] as? String ?? ""
        
        return ParsedSearchResult( key: key, name: name, personal_name: personal_name, birth_date: birth_date, death_date: death_date, photos: photos, links: links, bio: bioText, alternate_names: alternate_names, wikipedia: wikipedia, revision: revision, latest_revision: latest_revision, created: created, last_modified: last_modified, type: type )
    }
    
    // MARK: Initialization
    init(
        key: String,
        name: String,
        personal_name: String,
        birth_date: String,
        death_date: String,
        
        photos: [Int],                // transformable
        links: [[String: String]],    // transformable
        bio: String,
        alternate_names: [String],    // transformable
        
        wikipedia: String,
        
        revision: Int64,
        latest_revision: Int64,
        
        created: NSDate?,
        last_modified: NSDate?,
        
        type: String
    ) {
        
        self.key = key
        self.name = name
        self.personal_name = personal_name
        self.birth_date = birth_date
        self.death_date = death_date
        
        self.photos = photos
        self.links = links
        self.bio = bio
        self.alternate_names = alternate_names
        
        self.wikipedia = wikipedia
        
        self.revision = revision
        self.latest_revision = latest_revision
        
        self.created = created
        self.last_modified = last_modified
        
        self.type = type
    }
}

/// An `Operation` to parse earthquakes out of a downloaded feed from the USGS.
class WorkDetailParseOperation: Operation {
    
    let cacheFile: NSURL
    let context: NSManagedObjectContext
    let resultHandler: ObjectResultClosure?

    var searchResults = SearchResults()
    
    var objectID: NSManagedObjectID?
    
    /**
        - parameter cacheFile: The file `NSURL` from which to load Work query data.
        - parameter context: The `NSManagedObjectContext` that will be used as the
                             basis for importing data. The operation will internally
                             construct a new `NSManagedObjectContext` that points
                             to the same `NSPersistentStoreCoordinator` as the
                             passed-in context.
    */
    init( cacheFile: NSURL, coreDataStack: CoreDataStack, resultHandler: ObjectResultClosure? ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.cacheFile = cacheFile
        self.context = coreDataStack.newChildContext()
        self.context.mergePolicy = NSOverwriteMergePolicy
        self.resultHandler = resultHandler
        
        super.init()

        name = "Parse Work Detail Results"
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

        context.performBlock {
            
            if let newObject = OLWorkDetail.parseJSON( "", index: 0, json: resultSet, moc: self.context ) {
            
                // sometimes we have one or more editions without an associated work
                if "/type/edition" == newObject.type {
                    
                    _ = OLEditionDetail.parseJSON( "", workKey: newObject.key, index: 0, json: resultSet, moc: self.context )
                }
                
                let error = self.saveContext()
                
                if nil == error && nil != self.resultHandler {
                    
                    self.resultHandler!( objectID: newObject.objectID )
                }

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
