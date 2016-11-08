//  LanguagesParseOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/16/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation
import CoreData

import BNRCoreDataStack
import PSOperations

/// An `Operation` to parse works out of a query from OpenLibrary.
class LanguagesParseOperation: PSOperation {
    
    let cacheFile: URL
    let context: NSManagedObjectContext
    
    /**
        - parameter cacheFile: The file `NSURL` from which to load author query data.
        - parameter context: The `NSManagedObjectContext` that will be used as the
                             basis for importing data. The operation will internally
                             construct a new `NSManagedObjectContext` that points
                             to the same `NSPersistentStoreCoordinator` as the
                             passed-in context.
    */
    init( cacheFile: URL, coreDataStack: OLDataStack ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.cacheFile = cacheFile
        self.context = coreDataStack.newChildContext( name: "saveLanguages" )
        self.context.mergePolicy = NSOverwriteMergePolicy
        
        super.init()

        name = "Parse Language Codes"
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
            if let json = try JSONSerialization.jsonObject(with: stream, options: []) as? [[String: AnyObject]] {
            
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
    
    fileprivate func parse( _ resultSet: [[String: AnyObject]] ) {

        let numFound = resultSet.count
        if 0 >= numFound {
            
            finishWithError( nil )
            return
        }

        context.perform {
            
            let sequence = Int64( 0 )
            var index: Int64 = 0
            for entry in resultSet {
                
                if nil != OLLanguage.parseJSON( sequence, index: index, json: entry, moc: self.context ) {
                
                    index += 1
                    
//                    print( "\(newObject.key) \(newObject.code) \(newObject.name)" )
                }
            }

            let error = self.saveContext()

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
