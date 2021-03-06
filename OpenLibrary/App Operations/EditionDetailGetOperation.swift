//  EditionDetailGetOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/2/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import CoreData

//import BNRCoreDataStack
import PSOperations

/// A composite `Operation` to both download and parse Work search result data.
class EditionDetailGetOperation: GroupOperation {

    // MARK: Properties
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
    init( queryText: String, parentObjectID: NSManagedObjectID?, currentObjectID: NSManagedObjectID?, dataStack: OLDataStack, completionHandler: @escaping () -> Void ) {

        let cachesFolder = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        let parts = queryText.components( separatedBy: "/" )
        let goodParts = parts.filter { (x) -> Bool in !x.isEmpty }
        let editionKey = goodParts.last!
        let cacheFile = cachesFolder.appendingPathComponent("\(editionKey)EditionDetailResults.json")
//        print( "cache: \(cacheFile.absoluteString)" )
        
        /*
            This operation is made of three child operations:
            1. The operation to download the JSON feed
            2. The operation to parse the JSON feed and insert the elements into the Core Data store
            3. The operation to invoke the completion handler
        
            There is an optional operation 0 to delete the existing contents of the Core Data store
        */
        downloadOperation = EditionDetailDownloadOperation( queryText: queryText, cacheFile: cacheFile )
        parseOperation = EditionDetailParseOperation( parentObjectID: parentObjectID, currentObjectID: currentObjectID, cacheFile: cacheFile, dataStack: dataStack )
        
        let finishOperation = PSBlockOperation { completionHandler() }
        
        // These operations must be executed in order
        parseOperation.addDependency(downloadOperation)
        finishOperation.addDependency(parseOperation)
        
        super.init( operations: [downloadOperation, parseOperation, finishOperation] )

        addCondition( MutuallyExclusive<EditionDetailGetOperation>() )
        
        name = "Get Edition Detail"
    }
    
    override func operationDidFinish(_ operation: Foundation.Operation, withErrors errors: [NSError]) {
        if let firstError = errors.first , (operation === downloadOperation || operation === parseOperation) {
            produceAlert(firstError)
       }
    }
    
}

