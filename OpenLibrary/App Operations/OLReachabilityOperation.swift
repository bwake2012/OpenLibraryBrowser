//
//  OLReachabilityOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 7/17/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

class OLReachabilityOperation: GroupOperation {

    static let hostKey = "Host"
    static let name = "Reachability"

    private var hasProducedAlert = false
    
    private let downloadOperation: OLReachabilityDownloadOperation
    private let finishOperation: NSBlockOperation
    
    private let host: String

    init( host: String, completionHandler: Void -> Void ) {
        
        self.host = host
        
        downloadOperation = OLReachabilityDownloadOperation( host: host )
        finishOperation = NSBlockOperation( block: completionHandler )

        // These operations must be executed in order
        finishOperation.addDependency(downloadOperation)
        
        super.init( operations: [downloadOperation, finishOperation] )
        
        addCondition( MutuallyExclusive<OLReachabilityOperation>() )
        
        queuePriority = .High
        
        name = "OpenLibrary Reachability Operation"
    }
    
    deinit {
    
    }
    
    override func operationDidFinish( operation: NSOperation, withErrors errors: [NSError] ) {

        if operation === downloadOperation {
            
            if let firstError = errors.first {
            
                produceAlert(firstError)
            
            } else if operation.cancelled {
                
                produceAlert(
                    NSError(
                        code: .ConditionFailed,
                        userInfo: [
                                OperationConditionKey: self.dynamicType.name,
                                self.dynamicType.hostKey: self.host
                            ]
                        )
                    )
            }
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
        
        let failedOther = (NSURLErrorDomain, -1200, nil as String?)
        
        switch errorReason {
        case failedReachability:
            // We failed because the network isn't reachable.
            let hostURL = error.userInfo[ReachabilityCondition.hostKey] as! NSURL
            
            alert.title = "Unable to Connect"
            alert.message = "Cannot connect to \(hostURL.host!). Make sure your device is connected to the internet and try again."
            
        case failedJSON:
            // We failed because the JSON was malformed.
            alert.title = "Unable to Download"
            alert.message = "Cannot parse General Search results. Try again later."
            
        case failedOther:
            alert.title = "At Starbucks"
            alert.message = "Please log on to the WiFi access point."
            
        default:
            return
        }
        
        produceOperation(alert)
        hasProducedAlert = true
    }
    
    override func finished( errors: [NSError] ) {
        
        if let firstError = errors.first {
            
            produceAlert(firstError)
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
