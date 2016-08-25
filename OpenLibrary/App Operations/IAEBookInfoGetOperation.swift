//  InternetArchiveEbookInfoGetOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/16/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

//  https://openlibrary.org/authors/OL26320A/works.json

import CoreData

import BNRCoreDataStack
import PSOperations

/// A composite `Operation` to both download and parse the list of language data.
class InternetArchiveEbookInfoGetOperation: GroupOperation {
    // MARK: Properties
    
    let downloadOperation: IAEBookInfoDownloadOperation
    let parseOperation: InternetArchiveEbookInfoParseOperation
   
//    private var hasProducedAlert = false
    
    /**
        - parameter context: The `NSManagedObjectContext` into which the parsed
                             author query results will be imported.

        - parameter completionHandler: The handler to call after downloading and
                                       parsing are complete. This handler will be
                                       invoked on an arbitrary queue.
    */
    init( eBookKey: String, coreDataStack: CoreDataStack, completionHandler: Void -> Void ) {

        let cachesFolder = try! NSFileManager.defaultManager().URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)

        let cacheFile = cachesFolder.URLByAppendingPathComponent("\(eBookKey)IAEBookInfo.xml")
//        print( "cache: \(cacheFile.absoluteString)" )
        
        /*
            This operation is made of three child operations:
            1. The operation to download the JSON feed
            2. The operation to parse the JSON feed and insert the elements into the Core Data store
            3. The operation to invoke the completion handler
        */
        downloadOperation = IAEBookInfoDownloadOperation( eBookKey: eBookKey, cacheFile: cacheFile )
        parseOperation =
            InternetArchiveEbookInfoParseOperation(
                    eBookKey: eBookKey,
                    cacheFile: cacheFile,
                    coreDataStack: coreDataStack
                )
        
        let finishOperation = NSBlockOperation( block: completionHandler )
        
        // These operations must be executed in order
        parseOperation.addDependency(downloadOperation)
        finishOperation.addDependency(parseOperation)
        
        let operations = [downloadOperation, parseOperation, finishOperation]
        super.init( operations: operations )

        addCondition( MutuallyExclusive<InternetArchiveEbookInfoGetOperation>() )
        
        name = "Get IAEBookInfo"
    }
    
    override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
        if let firstError = errors.first where (operation === downloadOperation || operation === parseOperation) {
            produceAlert(firstError)
        }
    }
    
}

