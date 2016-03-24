//  ImageParseOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/2/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple Earthquakes sample app in the Advanced NSOperations project

import Foundation
import CoreData

import BNRCoreDataStack

/// A struct to represent a parsed author search result.
private struct ParsedSearchResult {
    
    // MARK: Static Properties
    // birth and death dates must be converted to NSDate
    private static let dateFormatter: NSDateFormatter = {
        
        let f = NSDateFormatter()
        f.locale = NSLocale( localeIdentifier: "en_US_POSIX" )
        f.dateFormat = "dd' 'MMMM' 'yyyy"
        f.timeZone = NSTimeZone( abbreviation: "UTC" )

        return ( f )
    }()
    
    // time stamps must be converted to NSDate
    // 2011-12-02T18:33:15.439307
    private static let timestampFormatter: NSDateFormatter = {
        
        let f = NSDateFormatter()
        f.locale = NSLocale( localeIdentifier: "en_US_POSIX" )
        f.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSSSS"
        f.timeZone = NSTimeZone( abbreviation: "UTC" )
        
        return ( f )
    }()

    // MARK: Properties.

    let key: String
    let name: String
    let personal_name: String
    let birth_date: NSDate?
    let death_date: NSDate?
    
    let photos: [Int]                // transformable
    let links: [[String: String]]    // transformable
    let bio: [String: String]        // transformable
    let alternate_names: [String]    // transformable
    
    let revision: Int
    let latest_revision: Int
    
    let created: NSDate?
    let last_modified: NSDate?
    
    let type: String
    
    // MARK: Initialization
    
    init?( match: [String: AnyObject] ) {
        
        guard let key = match["key"] as? String else { return nil }
        self.key = key
        
        guard let name = match["name"] as? String else { return nil }
        self.name = name
        
        self.personal_name = match["personal_name"] as? String ?? ""
        
        self.birth_date = ParsedSearchResult.dateFormatter.dateFromString( match["birth_date"] as? String ?? "" )
        self.death_date = ParsedSearchResult.dateFormatter.dateFromString( match["death_date"] as? String ?? "" )
        
        var tempPhotos = [Int]()
        if let photos = match["photos"] as? [AnyObject] {
            
            for photo in photos {
                
                if let n = photo as? Int {
                    
                    tempPhotos.append( n )
                }
            }
            
        }
        self.photos = tempPhotos

        self.links = match["links"] as? [[String: String]] ?? [[String: String]]()
        self.bio = match["bio"] as? [String: String]   ?? [String: String]()
        self.alternate_names = match["alternate_names"] as? [String] ?? [String]()
        
        self.revision = match["revision"] as? Int ?? 0
        self.latest_revision = match["latest_revision"] as? Int ?? 0
        
        if let createdTimestamp = match["created"] as? [String: String] {
            self.created = ParsedSearchResult.timestampFormatter.dateFromString( createdTimestamp["value"] ?? "" )
        } else {
            
            self.created = ParsedSearchResult.timestampFormatter.dateFromString( "" )
        }
        if let madifiedTimestamp = match["last_modified"] as? [String: String] {
            self.last_modified = ParsedSearchResult.timestampFormatter.dateFromString( madifiedTimestamp["value"] ?? "" )
        } else {
            
            self.last_modified = ParsedSearchResult.timestampFormatter.dateFromString( "" )
        }

        self.type = match["type"] as? String ?? ""
    }
}

/// An `Operation` to parse earthquakes out of a downloaded feed from the USGS.
class ImageParseOperation: Operation {
    
    let cacheFile: NSURL
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
    init( imageFile: NSURL, coreDataStack: CoreDataStack ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.cacheFile = imageFile
        self.context = coreDataStack.newBackgroundWorkerMOC()
        self.context.mergePolicy = NSOverwriteMergePolicy
        
        super.init()

        name = "Parse Image Results"
    }
    
    deinit {
        
        print( "ImageParseOperation deinit" )
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
            
            if let newResult = ParsedSearchResult( match: resultSet ) {

                self.insert( newResult )
                
                print( "\(newResult.name)" )
            }

            let error = self.saveContext()

            self.finishWithError( error )
        }
    }
    
    private func insert( parsed: ParsedSearchResult ) {

        let result = NSEntityDescription.insertNewObjectForEntityForName( OLImage.entityName, inManagedObjectContext: context ) as! OLImage
        
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
