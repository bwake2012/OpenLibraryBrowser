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
    init( queryText: String, coreDataStack: CoreDataStack, completionHandler: Void -> Void ) {

        self.coreDataStack = coreDataStack
        
        let cachesFolder = try! NSFileManager.defaultManager().URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)

        let parts = queryText.componentsSeparatedByString( "/" )
        let goodParts = parts.filter { (x) -> Bool in !x.isEmpty }
        let olid = goodParts.last!
        let cacheFile = cachesFolder.URLByAppendingPathComponent("\(olid)workEditionEbooksList.json")
//        print( "cache: \(cacheFile.absoluteString)" )
        
        /*
            This operation is made of three child operations:
            1. The operation to download the JSON feed
            2. The operation to parse the JSON feed and insert the elements into the Core Data store
            3. The operation to invoke the completion handler
        
            There is an optional operation 0 to delete the existing contents of the Core Data store
        */
        downloadOperation = WorkEditionListDownloadOperation( queryText: queryText, cacheFile: cacheFile )
        parseOperation = WorkEditionListParseOperation( parentKey: queryText, cacheFile: cacheFile )
        
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
    
//    private func produceAlert(error: NSError) {
//        /*
//            We only want to show the first error, since subsequent errors might
//            be caused by the first.
//        */
//        if hasProducedAlert { return }
//        
//        let alert = AlertOperation()
//        
//        let errorReason = (error.domain, error.code, error.userInfo[OperationConditionKey] as? String)
//        
//        // These are examples of errors for which we might choose to display an error to the user
//        let failedReachability = (OperationErrorDomain, OperationErrorCode.ConditionFailed, ReachabilityCondition.name)
//        
//        let failedJSON = (NSCocoaErrorDomain, NSPropertyListReadCorruptError, nil as String?)
//
//        switch errorReason {
//            case failedReachability:
//                // We failed because the network isn't reachable.
//                let hostURL = error.userInfo[ReachabilityCondition.hostKey] as! NSURL
//                
//                alert.title = "Unable to Connect"
//                alert.message = "Cannot connect to \(hostURL.host!). Make sure your device is connected to the internet and try again."
//            
//            case failedJSON:
//                // We failed because the JSON was malformed.
//                alert.title = "Unable to Download"
//                alert.message = "Cannot parse Work Editions eBook results. Try again later."
//
//            default:
//                return
//        }
//        
//        produceOperation(alert)
//        hasProducedAlert = true
//    }
}

// Operators to use in the switch statement.
private func ~=(lhs: (String, Int, String?), rhs: (String, Int, String?)) -> Bool {
    return lhs.0 ~= rhs.0 && lhs.1 ~= rhs.1 && lhs.2 == rhs.2
}

private func ~=(lhs: (String, OperationErrorCode, String), rhs: (String, Int, String?)) -> Bool {
    return lhs.0 ~= rhs.0 && lhs.1.rawValue ~= rhs.1 && lhs.2 == rhs.2
}
