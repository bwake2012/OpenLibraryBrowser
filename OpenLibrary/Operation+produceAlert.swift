//
//  Operation+produceAlert.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 7/19/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

import ObjectiveC

import PSOperations

var AssociatedObjectHandle: UInt8 = 0

extension Operation {
    
    var hasProducedAlert: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectHandle) as? Bool ?? false
        }
        
        set {
            objc_setAssociatedObject(self, &AssociatedObjectHandle, newValue, objc_AssociationPolicy (rawValue: 01401)! ) // (OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }
    
    func produceAlert(error: NSError) {
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
            alert.title = "Not Logged In to WiFi"
            alert.message = "Please log on to the WiFi access point."
            
        default:
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
