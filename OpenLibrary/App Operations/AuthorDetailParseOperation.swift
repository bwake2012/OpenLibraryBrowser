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

/// An `Operation` to parse earthquakes out of a downloaded feed from the USGS.
class AuthorDetailParseOperation: PSOperation {
    
    let parentObjectID: NSManagedObjectID?
    let cacheFile: URL
    let context: NSManagedObjectContext

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
    init( parentObjectID: NSManagedObjectID?, cacheFile: URL, dataStack: OLDataStack ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.parentObjectID = parentObjectID

        self.cacheFile = cacheFile
        self.context = dataStack.newChildContext( name: "AuthorDetailParse Context" )
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
                
                print( "\(String(describing: error))" )
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
}
