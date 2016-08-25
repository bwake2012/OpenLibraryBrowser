//  WorkEditionEbooksGetOperation.swift
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
class WorkEditionEbooksGetOperation: GroupOperation {
    // MARK: Properties
    
    let downloadOperation: WorkEditionListDownloadOperation
    let parseOperation: WorkEditionListParseOperation
    let finishOperation: NSBlockOperation
   
//    private var hasProducedAlert = false
    
    private let coreDataStack: CoreDataStack
     
    /**
        - parameter coreDataStack: The Big Nerd Ranch Core Data Stack 
                                   which will furnish the MOC to store the result

        - parameter completionHandler: The handler to call after downloading and
                                       parsing are complete. This handler will be
                                       invoked on an arbitrary queue.
    */
    init( workKey: String, coreDataStack: CoreDataStack, completionHandler: Void -> Void ) {

        self.coreDataStack = coreDataStack
        
        let cachesFolder = try! NSFileManager.defaultManager().URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)

        let parts = workKey.componentsSeparatedByString( "/" )
        let goodParts = parts.filter { (x) -> Bool in !x.isEmpty }
        let olid = goodParts.last!
        let cacheFile =
            cachesFolder.URLByAppendingPathComponent("\(olid)workEditionEbooksList.json")
//        print( "cache: \(cacheFile.absoluteString)" )
        
        /*
            This operation is made of three child operations:
            1. The operation to download the JSON feed
            2. The operation to parse the JSON feed and insert the elements into the Core Data store
            3. The operation to invoke the completion handler
        
            There is an optional operation 0 to delete the existing contents of the Core Data store
        */
        downloadOperation = WorkEditionListDownloadOperation( workKey: workKey, cacheFile: cacheFile )
        parseOperation = WorkEditionListParseOperation( parentKey: workKey, cacheFile: cacheFile )
        
        finishOperation = NSBlockOperation( block: completionHandler )
        
        // These operations must be executed in order
        parseOperation.addDependency(downloadOperation)
        finishOperation.addDependency(parseOperation)
        
        let operations = [downloadOperation, parseOperation, finishOperation]
        super.init( operations: operations )

        addCondition( MutuallyExclusive<WorkEditionsGetOperation>() )
        
        name = "Get Work Edition List"
    }
    
    override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {

        if let firstError = errors.first where (operation === downloadOperation || operation === parseOperation) {
            
            produceAlert(firstError)
        
        } else if operation == parseOperation {
            
            if !parseOperation.editions.isEmpty {
                
                let ebookOperation =
                    IAEBookItemListGetOperation(
                            editionKeys: parseOperation.editions, coreDataStack: coreDataStack, completionHandler: {}
                        )
                
                finishOperation.addDependency( ebookOperation )
                
                addOperation( ebookOperation )
            }
        }
    }
    
}

