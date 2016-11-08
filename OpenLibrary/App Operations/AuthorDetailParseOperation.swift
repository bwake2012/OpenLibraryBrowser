//  AuthorDetailParseOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/2/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation
import CoreData

import BNRCoreDataStack
import PSOperations

/// An object to represent a parsed author search result.
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
    
    let created: Date?
    let last_modified: Date?
    
    let type: String
    
    // MARK: Class Factory
    
    class func fromJSON ( _ match: [String: AnyObject] ) -> ParsedSearchResult? {
        
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
        
        var revision = match["revision"] as? Int64
        var latest_revision = match["latest_revision"] as? Int64
        if nil == revision && nil != latest_revision {
            
            revision = latest_revision
            
        } else if nil == latest_revision && nil != revision {
            
            latest_revision = revision
            
        } else if nil == revision && nil == latest_revision {
            
            revision = Int64( 0 )
            latest_revision = Int64( 0 )

        }
        
        var created = OpenLibraryObject.OLTimeStamp( match["created"] )
        var last_modified = OpenLibraryObject.OLTimeStamp( match["last_modified"] )
        if nil == created && nil != last_modified {
            
            created = last_modified
        
        } else if nil == last_modified && nil != created {
            
            last_modified = created
        }
        
        let type = match["type"] as? String ?? ""
        
        assert( nil != created )
        assert( nil != last_modified )
        assert( nil != revision )
        assert( nil != latest_revision )
        
        return ParsedSearchResult( key: key, name: name, personal_name: personal_name, birth_date: birth_date, death_date: death_date, photos: photos, links: links, bio: bioText, alternate_names: alternate_names, wikipedia: wikipedia, revision: revision!, latest_revision: latest_revision!, created: created, last_modified: last_modified, type: type )
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
        
        created: Date?,
        last_modified: Date?,
        
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
class AuthorDetailParseOperation: PSOperation {
    
    let parentObjectID: NSManagedObjectID?
    let cacheFile: URL
    let context: NSManagedObjectContext

    var searchResults = SearchResults()
    
    var photos = [Int]()
    var localThumbURL: URL?
    var localMediumURL: URL?
    var localLargeURL: URL?
    
    /**
        - parameter cacheFile: The file `NSURL` from which to load author query data.
        - parameter context: The `NSManagedObjectContext` that will be used as the
                             basis for importing data. The operation will internally
                             construct a new `NSManagedObjectContext` that points
                             to the same `NSPersistentStoreCoordinator` as the
                             passed-in context.
    */
    init( parentObjectID: NSManagedObjectID?, cacheFile: URL, coreDataStack: OLDataStack ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.parentObjectID = parentObjectID

        self.cacheFile = cacheFile
        self.context = coreDataStack.newChildContext( name: "AuthorDetailParse Context" )
        self.context.mergePolicy = NSOverwriteMergePolicy
        
        super.init()

        name = "Parse Author Detail Results"
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

        context.perform {
            
            if let newObject = OLAuthorDetail.parseJSON( self.parentObjectID, json: resultSet, moc: self.context ) {

                self.photos = newObject.photos
                if !newObject.photos.isEmpty {
                    self.photos = newObject.photos
                    self.localThumbURL  = newObject.localURL( "S" )
                    self.localMediumURL = newObject.localURL( "M" )
                    self.localLargeURL  = newObject.localURL( "L" )
                }
                
//                print( "detail: \(newObject.name)" )
            }

            let error = self.saveContext()
            if nil != error {
                
                print( "\(error)" )
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
            try context.saveContextAndWait()
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
