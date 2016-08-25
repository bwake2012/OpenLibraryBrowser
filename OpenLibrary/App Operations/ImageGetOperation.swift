//  ImageGetOperation.swift
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
class ImageGetOperation: GroupOperation {
    // MARK: Properties
    
    let downloadOperation: ImageDownloadOperation
   
//    private var hasProducedAlert = false
    
    /**
        - parameter context: The `NSManagedObjectContext` into which the parsed
                             author query results will be imported.

        - parameter completionHandler: The handler to call after downloading and
                                       parsing are complete. This handler will be
                                       invoked on an arbitrary queue.
    */
    init( stringID: String, imageKeyName: String, localURL: NSURL, size: String, type: String, completionHandler: Void -> Void ) {
        
        downloadOperation =
            ImageDownloadOperation( stringID: stringID, imageKeyName: imageKeyName, size: size, type: type, imageURL: localURL )
        let finishOperation = NSBlockOperation( block: completionHandler )
        
        // These operations must be executed in order
        finishOperation.addDependency(downloadOperation)
        
        super.init( operations: [downloadOperation, finishOperation] )
        
        queuePriority = .Low
        
//        addCondition( MutuallyExclusive<ImageGetOperation>() )

        name = "Get Image"
    }

    convenience init( numberID: Int, imageKeyName: String, localURL: NSURL, size: String, type: String, completionHandler: Void -> Void ) {

        self.init( stringID: String( numberID ), imageKeyName: imageKeyName, localURL: localURL, size: size, type: type, completionHandler: completionHandler )
    }
    
    override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
        if let firstError = errors.first where (operation === downloadOperation) {
            produceAlert(firstError)
        }
    }
    
}

