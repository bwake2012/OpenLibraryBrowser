//  TitleSearchOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import CoreData

import PSOperations

/// A composite `Operation` to both download and parse Title search result data.
class TitleSearchOperation: GroupOperation {
    // MARK: Properties
    
//    var deleteOperation: TitleSearchResultsDeleteOperation?
    let downloadOperation: TitleSearchResultsDownloadOperation
    let parseOperation: TitleSearchResultsParseOperation
   
//    private var hasProducedAlert = false
    
    fileprivate let coreDataStack: OLDataStack
    
    /**
        - parameter context: The `NSManagedObjectContext` into which the parsed
                             Title query results will be imported.

        - parameter completionHandler: The handler to call after downloading and
                                       parsing are complete. This handler will be
                                       invoked on an arbitrary queue.
    */
    init( queryText: String, offset: Int, limit: Int, coreDataStack: OLDataStack, updateResults: @escaping SearchResultsUpdater, completionHandler: @escaping () -> Void ) {

        self.coreDataStack = coreDataStack
        
        var cacheFile = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        cacheFile.appendPathComponent( "TitleSearchResults.json" )
//        print( "cache: \(cacheFile.absoluteString)" )
        
        /*
            This operation is made of three child operations:
            1. The operation to download the JSON feed
            2. The operation to parse the JSON feed and insert the elements into the Core Data store
            3. The operation to invoke the completion handler
        
            There is an optional operation 0 to delete the existing contents of the Core Data store
        */
        downloadOperation = TitleSearchResultsDownloadOperation( queryText: queryText, offset: offset, limit: limit, cacheFile: cacheFile )
        parseOperation = TitleSearchResultsParseOperation( cacheFile: cacheFile, coreDataStack: coreDataStack, updateResults: updateResults )
        
        let finishOperation = PSBlockOperation { completionHandler() }
        
        // These operations must be executed in order
        parseOperation.addDependency(downloadOperation)
        finishOperation.addDependency(parseOperation)
        
        var operations: [Foundation.Operation] = []
//        if 0 == offset {
//            deleteOperation = TitleSearchResultsDeleteOperation( coreDataStack: coreDataStack )
//            if let dO = deleteOperation {
//                downloadOperation.addDependency( dO )
//                operations.append( dO )
//            }
//        }
        
        operations.append( downloadOperation )
        operations.append( parseOperation )
        operations.append( finishOperation )
        
        super.init( operations: operations )

        addCondition( MutuallyExclusive<TitleSearchOperation>() )
        
        name = "Title Search " + queryText
    }
    
    override func operationDidFinish(_ operation: Foundation.Operation, withErrors errors: [NSError]) {
        if let firstError = errors.first {

            if operation === downloadOperation || operation === parseOperation {
                produceAlert(firstError)
            }
        }
    }
    
}

