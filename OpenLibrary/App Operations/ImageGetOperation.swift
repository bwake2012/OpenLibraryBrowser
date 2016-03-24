//  ImageGetOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/2/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import CoreData

import BNRCoreDataStack

/// A composite `Operation` to both download and parse author search result data.
class ImageGetOperation: GroupOperation {
    // MARK: Properties
    
    let downloadOperation: ImageDownloadOperation
   
    private var hasProducedAlert = false
    
    /**
        - parameter context: The `NSManagedObjectContext` into which the parsed
                             author query results will be imported.

        - parameter completionHandler: The handler to call after downloading and
                                       parsing are complete. This handler will be
                                       invoked on an arbitrary queue.
    */
    init( stringID: String, imageKeyName: String, localURL: NSURL, size: String, type: String, completionHandler: Void -> Void ) {
        
        downloadOperation =
            ImageDownloadOperation( stringID: stringID, imageKeyName: imageKeyName, size: size, type: type, imageFile: localURL )
        let finishOperation = NSBlockOperation( block: completionHandler )
        
        // These operations must be executed in order
        finishOperation.addDependency(downloadOperation)
        
        super.init( operations: [downloadOperation, finishOperation] )
        
        name = "Get Image"
    }

    convenience init( numberID: Int, imageKeyName: String, localURL: NSURL, size: String, type: String, completionHandler: Void -> Void ) {

        self.init( stringID: String( numberID ), imageKeyName: imageKeyName, localURL: localURL, size: size, type: type, completionHandler: completionHandler )
    }
    
    deinit {
        
        print( "\(self.dynamicType.description()) deinit" )
    }
    
    override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
        if let firstError = errors.first where (operation === downloadOperation) {
            produceAlert(firstError)
        }
    }
    
    private func produceAlert(error: NSError) {
        /*
            We only want to show the first error, since subsequent errors might
            be caused by the first.
        */
        if hasProducedAlert { return }
        
        let alert = AlertOperation()
        
        let errorReason = (error.domain, error.code, error.userInfo[OperationConditionKey] as? String)
        
        // These are examples of errors for which we might choose to display an error to the user
        let failedReachability = (OperationErrorDomain, OperationErrorCode.ConditionFailed, ReachabilityCondition.name)
        
        let failedJSON = (NSCocoaErrorDomain, NSPropertyListReadCorruptError, nil as String?)

        switch errorReason {
            case failedReachability:
                // We failed because the network isn't reachable.
                let hostURL = error.userInfo[ReachabilityCondition.hostKey] as! NSURL
                
                alert.title = "Unable to Connect"
                alert.message = "Cannot connect to \(hostURL.host!). Make sure your device is connected to the internet and try again."
            
            case failedJSON:
                // We failed because the JSON was malformed.
                alert.title = "Unable to Download"
                alert.message = "Cannot parse Author Search results. Try again later."

            default:
                print( "\(errorReason)" )
                return
        }
        
        produceOperation(alert)
        hasProducedAlert = true
    }
    
}

// Operators to use in the switch statement.
private func ~=(lhs: (String, Int, String?), rhs: (String, Int, String?)) -> Bool {
    return lhs.0 ~= rhs.0 && lhs.1 ~= rhs.1 && lhs.2 == rhs.2
}

private func ~=(lhs: (String, OperationErrorCode, String), rhs: (String, Int, String?)) -> Bool {
    return lhs.0 ~= rhs.0 && lhs.1.rawValue ~= rhs.1 && lhs.2 == rhs.2
}
