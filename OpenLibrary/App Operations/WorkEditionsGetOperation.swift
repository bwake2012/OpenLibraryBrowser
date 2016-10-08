//  WorkEditionsGetOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

//  https://openlibrary.org/works/OL262759W/editions.json?*=

import CoreData

import BNRCoreDataStack
import PSOperations

/// A composite `Operation` to both download and parse work editions data.
class WorkEditionsGetOperation: GroupOperation {
    // MARK: Properties
    
    let downloadOperation: WorkEditionsDownloadOperation
    let parseOperation: WorkEditionsParseOperation
   
//    private var hasProducedAlert = false
     
    /**
        - parameter context: The `NSManagedObjectContext` into which the parsed
                             author query results will be imported.

        - parameter completionHandler: The handler to call after downloading and
                                       parsing are complete. This handler will be
                                       invoked on an arbitrary queue.
    */
    init( queryText: String, objectID: NSManagedObjectID?, offset: Int, limit: Int, coreDataStack: CoreDataStack, updateResults: SearchResultsUpdater, completionHandler: Void -> Void ) {

        let cachesFolder = try! NSFileManager.defaultManager().URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)

        let parts = queryText.componentsSeparatedByString( "/" )
        let goodParts = parts.filter { (x) -> Bool in !x.isEmpty }
        let workKey = goodParts.last!
        let cacheFile = cachesFolder.URLByAppendingPathComponent("\(workKey)workEditions.json")
//        print( "cache: \(cacheFile.absoluteString)" )
        
        /*
            This operation is made of three child operations:
            1. The operation to download the JSON feed
            2. The operation to parse the JSON feed and insert the elements into the Core Data store
            3. The operation to invoke the completion handler
        
            There is an optional operation 0 to delete the existing contents of the Core Data store
        */
        downloadOperation = WorkEditionsDownloadOperation( queryText: queryText, offset: offset, limit: limit, cacheFile: cacheFile )
        parseOperation = WorkEditionsParseOperation( parentKey: queryText, parentObjectID: objectID, offset: offset, limit: limit, cacheFile: cacheFile, coreDataStack: coreDataStack, updateResults: updateResults )
        
        let finishOperation = NSBlockOperation( block: completionHandler )
        
        // These operations must be executed in order
        parseOperation.addDependency(downloadOperation)
        finishOperation.addDependency(parseOperation)
        
        let operations = [downloadOperation, parseOperation, finishOperation]
        super.init( operations: operations )

        addCondition( MutuallyExclusive<WorkEditionsGetOperation>() )
        
        name = "Get Work Editions"
    }
    
    override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
        if let firstError = errors.first where (operation === downloadOperation || operation === parseOperation) {
            produceAlert(firstError)
        }
    }
    
}

