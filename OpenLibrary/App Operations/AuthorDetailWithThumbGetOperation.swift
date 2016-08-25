//  AuthorDetailWithThumbGetOperation.swift
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
class AuthorDetailWithThumbGetOperation: GroupOperation {
    // MARK: Properties
    
    let downloadOperation: AuthorDetailDownloadOperation
    let parseOperation: AuthorDetailParseOperation
    let finishOperation: NSBlockOperation
   
    var getThumbOperation: ImageGetOperation?
    var getMediumOperation: ImageGetOperation?
    var getLargeOperation: ImageGetOperation?
    
//    private var hasProducedAlert = false
    
    private let queryText: String
    private let parentObjectID: NSManagedObjectID
    private let size: String
    
    /**
        - parameter context: The `NSManagedObjectContext` into which the parsed
                             author query results will be imported.

        - parameter completionHandler: The handler to call after downloading and
                                       parsing are complete. This handler will be
                                       invoked on an arbitrary queue.
    */
    init( queryText: String, parentObjectID: NSManagedObjectID, size: String, coreDataStack: CoreDataStack, completionHandler: Void -> Void ) {
        
        self.queryText = queryText
        self.parentObjectID = parentObjectID
        self.size = size

        let cachesFolder = try! NSFileManager.defaultManager().URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)

        let parts = queryText.componentsSeparatedByString( "/" )
        let goodParts = parts.filter { (x) -> Bool in !x.isEmpty }
        let authorKey = goodParts.last!
        let cacheFile = cachesFolder.URLByAppendingPathComponent("\(authorKey)AuthorDetailResults.json")
        
        /*
            This operation is made of three child operations:
            1. The operation to download the JSON feed
            2. The operation to parse the JSON feed and insert the elements into the Core Data store
            3. The operation to invoke the completion handler
        */
        downloadOperation = AuthorDetailDownloadOperation( queryText: queryText, cacheFile: cacheFile )
        parseOperation = AuthorDetailParseOperation( parentObjectID: parentObjectID, cacheFile: cacheFile, coreDataStack: coreDataStack )
        
        finishOperation = NSBlockOperation( block: completionHandler )
        
        // These operations must be executed in order
        parseOperation.addDependency(downloadOperation)
        finishOperation.addDependency(parseOperation)
        
        super.init( operations: [downloadOperation, parseOperation, finishOperation] )

        addCondition( MutuallyExclusive<AuthorDetailWithThumbGetOperation>() )
        
        name = "Get Author Detail with Thumbnail " + queryText
    }
    
    override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
        if let firstError = errors.first {
            
            if operation === downloadOperation || operation === parseOperation {
                produceAlert(firstError)
            }

        } else if operation === parseOperation {
            
            if !parseOperation.photos.isEmpty {

                let photoID = parseOperation.photos[0]
                var operation: GroupOperation?
                
                if "S" == size || "A" == size {
                    self.getThumbOperation =
                        ImageGetOperation(
                                numberID: photoID,
                                imageKeyName: "ID",
                                localURL: parseOperation.localThumbURL,
                                size: "S", type: "a",
                                completionHandler: {}
                            )
                    addOperation( getThumbOperation! )
                    operation = getThumbOperation
                }
                if "M" == size || "A" == size || "B" == size {
                    getMediumOperation =
                        ImageGetOperation(
                            numberID: photoID,
                            imageKeyName: "ID",
                            localURL: parseOperation.localMediumURL,
                            size: "M", type: "a",
                            completionHandler: {}
                        )
                    if let op = operation {
                        
                        getMediumOperation!.addDependency( op )
                    }
                    operation = getMediumOperation
                    addOperation( getMediumOperation! )
                }
                if "L" == size || "A" == size || "B" == size {
                    self.getLargeOperation =
                        ImageGetOperation(
                            numberID: photoID,
                            imageKeyName: "ID",
                            localURL: parseOperation.localLargeURL,
                            size: "L", type: "a",
                            completionHandler: {}
                        )
                    if let op = operation {
                        
                        getLargeOperation!.addDependency( op )
                    }
                    operation = getLargeOperation
                    addOperation( getLargeOperation! )
                }
                
                if let operation = operation {
                    
                    finishOperation.addDependency( operation )
                }
            }
        }
    }
    
}

