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
import PSOperations

// An `Operation` to parse earthquakes out of a downloaded feed from the USGS.
class WorkDetailParseOperation: PSOperation {
    
    let cacheFile: URL
    let context: NSManagedObjectContext
    var currentObjectID: NSManagedObjectID?
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
    init( currentObjectID: NSManagedObjectID?, cacheFile: URL, dataStack: OLDataStack, resultHandler: ObjectResultClosure? ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.currentObjectID = currentObjectID
        self.cacheFile = cacheFile
        self.context = dataStack.newChildContext( name: "WorkDetail child context" )
        self.context.mergePolicy = NSOverwriteMergePolicy
        self.resultHandler = resultHandler
        
        super.init()

        name = "Parse Work Detail Results"
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
            
            if let newObject = OLWorkDetail.parseJSON( "", index: -1, currentObjectID: self.currentObjectID, json: resultSet, moc: self.context ) {
            
                // sometimes we have one or more editions without an associated work
                if "/type/edition" == newObject.type {
                    
                    _ = OLEditionDetail.parseJSON( "", workKey: newObject.key, index: 0, currentObjectID: nil, json: resultSet, moc: self.context )
                }
                
                let error = self.saveContext()

                if nil == error && nil != self.resultHandler {

                    self.resultHandler!( newObject.objectID )
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
