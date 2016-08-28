//  EditionDetailGetOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/2/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import CoreData

import BNRCoreDataStack
import PSOperations

/// A composite `Operation` to both download and parse Work search result data.
class EditionDetailGetOperation: GroupOperation {
    // MARK: Properties
    var objectID: NSManagedObjectID?
    
    let downloadOperation: EditionDetailDownloadOperation
    let parseOperation: EditionDetailParseOperation
   
//    private var hasProducedAlert = false
    
    /**
        - parameter context: The `NSManagedObjectContext` into which the parsed
                             Work query results will be imported.

        - parameter completionHandler: The handler to call after downloading and
                                       parsing are complete. This handler will be
                                       invoked on an arbitrary queue.
    */
    init( queryText: String, coreDataStack: CoreDataStack, completionHandler: Void -> Void ) {

        let cachesFolder = try! NSFileManager.defaultManager().URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)

        let parts = queryText.componentsSeparatedByString( "/" )
        let goodParts = parts.filter { (x) -> Bool in !x.isEmpty }
        let editionKey = goodParts.last!
        let cacheFile = cachesFolder.URLByAppendingPathComponent("\(editionKey)EditionDetailResults.json")
//        print( "cache: \(cacheFile.absoluteString)" )
        
        /*
            This operation is made of three child operations:
            1. The operation to download the JSON feed
            2. The operation to parse the JSON feed and insert the elements into the Core Data store
            3. The operation to invoke the completion handler
        
            There is an optional operation 0 to delete the existing contents of the Core Data store
        */
        downloadOperation = EditionDetailDownloadOperation( queryText: queryText, cacheFile: cacheFile )
        parseOperation = EditionDetailParseOperation( cacheFile: cacheFile, coreDataStack: coreDataStack )
        
        let finishOperation = NSBlockOperation( block: completionHandler )
        
        // These operations must be executed in order
        parseOperation.addDependency(downloadOperation)
        finishOperation.addDependency(parseOperation)
        
        super.init( operations: [downloadOperation, parseOperation, finishOperation] )

        addCondition( MutuallyExclusive<EditionDetailGetOperation>() )
        
        name = "Get Work Detail"
    }
    
    override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
        if let firstError = errors.first where (operation === downloadOperation || operation === parseOperation) {
            produceAlert(firstError)
        } else if operation === parseOperation {
            
            objectID = parseOperation.objectID
        }
    }
    
}
