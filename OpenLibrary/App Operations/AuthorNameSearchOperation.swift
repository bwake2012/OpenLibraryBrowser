//  AuthorNameSearchOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import CoreData

//import BNRCoreDataStack
import PSOperations

/// A composite `Operation` to both download and parse author search result data.
class AuthorNameSearchOperation: GroupOperation {
    // MARK: Properties
    
    var deleteOperation: AuthorSearchResultsDeleteOperation?
    let downloadOperation: AuthorNameSearchResultsDownloadOperation
    let parseOperation: AuthorNameSearchResultsParseOperation
   
//    private var hasProducedAlert = false
    
    fileprivate let dataStack: OLDataStack
    
    /**
        - parameter context: The `NSManagedObjectContext` into which the parsed
                             author query results will be imported.

        - parameter completionHandler: The handler to call after downloading and
                                       parsing are complete. This handler will be
                                       invoked on an arbitrary queue.
    */
    init( queryText: String, offset: Int, limit: Int, dataStack: OLDataStack, updateResults: @escaping SearchResultsUpdater, completionHandler: @escaping () -> Void ) {

        self.dataStack = dataStack
        
        let cachesFolder = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        let cacheFile = cachesFolder.appendingPathComponent("authorSearchResults.json")
//        print( "cache: \(cacheFile.absoluteString)" )
        
        /*
            This operation is made of three child operations:
            1. The operation to download the JSON feed
            2. The operation to parse the JSON feed and insert the elements into the Core Data store
            3. The operation to invoke the completion handler
        
            There is an optional operation 0 to delete the existing contents of the Core Data store
        */
        downloadOperation = AuthorNameSearchResultsDownloadOperation( queryText: queryText, offset: offset, limit: limit, cacheFile: cacheFile )
        parseOperation = AuthorNameSearchResultsParseOperation( cacheFile: cacheFile, dataStack: dataStack, updateResults: updateResults )
        
        let finishOperation = PSBlockOperation { completionHandler() }
        
        // These operations must be executed in order
        parseOperation.addDependency(downloadOperation)
        finishOperation.addDependency(parseOperation)
        
        var operations: [PSOperation] = []
        if 0 == offset {
            deleteOperation = AuthorSearchResultsDeleteOperation( dataStack: dataStack )
            if let dO = deleteOperation {
                downloadOperation.addDependency( dO )
                operations.append( dO )
            }
        }
        
        operations += [downloadOperation, parseOperation, finishOperation]
        super.init( operations: operations )

        addCondition( MutuallyExclusive<AuthorNameSearchOperation>() )
        
        name = "Author Name Search " + queryText
    }
    
    override func operationDidFinish(_ operation: Foundation.Operation, withErrors errors: [NSError]) {
        if let firstError = errors.first {

            if operation === downloadOperation || operation === parseOperation {
                produceAlert(firstError)
            }
        }
    }
    
}

// Operators to use in the switch statement.
private func ~=(lhs: (String, Int, String?), rhs: (String, Int, String?)) -> Bool {
    return lhs.0 ~= rhs.0 && lhs.1 ~= rhs.1 && lhs.2 == rhs.2
}

private func ~=(lhs: (String, OperationErrorCode, String), rhs: (String, Int, String?)) -> Bool {
    return lhs.0 ~= rhs.0 && lhs.1.rawValue ~= rhs.1 && lhs.2 == rhs.2
}
