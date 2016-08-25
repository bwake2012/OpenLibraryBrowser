//  BookGetOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/2/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import CoreData

import BNRCoreDataStack
import PSOperations

/// A composite `Operation` to both download and parse author search result data.
class BookGetOperation: GroupOperation {
    // MARK: Properties
    
    let downloadOperation: BookDownloadOperation
   
//    private var hasProducedAlert = false
    
    /**
        - parameter context: The `NSManagedObjectContext` into which the parsed
                             author query results will be imported.

        - parameter completionHandler: The handler to call after downloading and
                                       parsing are complete. This handler will be
                                       invoked on an arbitrary queue.
    */

    init( cacheBookURL: NSURL, remoteBookURL: NSURL, completionHandler: Void -> Void ) {
        
        downloadOperation =
            BookDownloadOperation( cacheBookURL: cacheBookURL, remoteBookURL: remoteBookURL )
        let finishOperation = NSBlockOperation( block: completionHandler )
        
        // These operations must be executed in order
        finishOperation.addDependency(downloadOperation)
        
        super.init( operations: [downloadOperation, finishOperation] )
        
//        queuePriority = .Low
        
        addCondition( MutuallyExclusive<BookGetOperation>() )

        name = "Get book"
    }

    override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
        if let firstError = errors.first where (operation === downloadOperation) {
            produceAlert(firstError)
        }
    }
}

