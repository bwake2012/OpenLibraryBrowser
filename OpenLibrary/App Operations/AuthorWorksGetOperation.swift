//  AuthorWorksGetOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

//  https://openlibrary.org/authors/OL26320A/works.json

import CoreData

//import BNRCoreDataStack
import PSOperations

/// A composite `Operation` to both download and parse author search result data.
class AuthorWorksGetOperation: GroupOperation {
    // MARK: Properties
    
    let downloadOperation: AuthorWorksDownloadOperation
    let parseOperation: AuthorWorksParseOperation
   
//  private var hasProducedAlert = false
    
    /**
        - parameter context: The `NSManagedObjectContext` into which the parsed
                             author query results will be imported.

        - parameter completionHandler: The handler to call after downloading and
                                       parsing are complete. This handler will be
                                       invoked on an arbitrary queue.
    */
    init( queryText: String, parentObjectID: NSManagedObjectID?, offset: Int, limit: Int, dataStack: OLDataStack, updateResults: @escaping SearchResultsUpdater, completionHandler: @escaping () -> Void ) {

        let cachesFolder = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        let parts = queryText.components( separatedBy: "/" )
        let goodParts = parts.filter { (x) -> Bool in !x.isEmpty }
        let authorKey = goodParts.last!
        let cacheFile = cachesFolder.appendingPathComponent("\(authorKey)authorWorks.json")
//        print( "cache: \(cacheFile.absoluteString)" )
        
        /*
            This operation is made of three child operations:
            1. The operation to download the JSON feed
            2. The operation to parse the JSON feed and insert the elements into the Core Data store
            3. The operation to invoke the completion handler
        
            There is an optional operation 0 to delete the existing contents of the Core Data store
        */
        downloadOperation = AuthorWorksDownloadOperation( queryText: queryText, offset: offset, limit: limit, cacheFile: cacheFile )
        parseOperation = AuthorWorksParseOperation( authorKey: queryText, parentObjectID: parentObjectID, offset: offset, limit: limit, cacheFile: cacheFile, dataStack: dataStack, updateResults: updateResults )
        
        let finishOperation = PSBlockOperation { completionHandler() }
        
        // These operations must be executed in order
        parseOperation.addDependency(downloadOperation)
        finishOperation.addDependency(parseOperation)
        
        let operations = [downloadOperation, parseOperation, finishOperation] as [Foundation.Operation]
        super.init( operations: operations )

        addCondition( MutuallyExclusive<AuthorWorksGetOperation>() )
        
        name = "Get Author Works " + queryText
    }
    
    override func operationDidFinish(_ operation: Foundation.Operation, withErrors errors: [NSError]) {
        if let firstError = errors.first , (operation === downloadOperation || operation === parseOperation) {
            produceAlert(firstError)
        }
    }
    
}

