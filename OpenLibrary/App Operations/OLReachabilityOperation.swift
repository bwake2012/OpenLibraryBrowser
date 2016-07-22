//
//  OLReachabilityOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 7/17/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import PSOperations

class OLReachabilityOperation: GroupOperation {

    static let hostKey = "Host"
    static let name = "Reachability"

//    private var hasProducedAlert = false
    
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
                        code: OperationErrorCode.ConditionFailed,
                        userInfo: [
                                OperationConditionKey: self.dynamicType.name,
                                self.dynamicType.hostKey: self.host
                            ]
                        )
                    )
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
