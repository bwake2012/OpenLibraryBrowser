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

private var extensionPropertiesKey: UInt8 = 42

extension GroupOperation {
    
    fileprivate class ExtensionProperties {
        
        var hasProducedAlert: Bool = false
        
        init() {
            
            hasProducedAlert = false
        }
    }

    fileprivate var extensionProperties: ExtensionProperties {
        
        get {
            
            let obj = associatedObject( self, key: &extensionPropertiesKey ) { return ExtensionProperties() }
            return obj
                
        }
        
        set { associateObject( self, key: &extensionPropertiesKey, value: newValue ) }
    }
    
    var hasProducedAlert: Bool {

        get { return extensionProperties.hasProducedAlert }
        set { extensionProperties.hasProducedAlert = newValue }
    }
    
    func produceAlert( _ error: NSError ) {
        /*
         We only want to show the first error, since subsequent errors might
         be caused by the first.
         */
        if hasProducedAlert { return }
        
        var alert: AlertOperation?
        
        var html: HTMLPageOperation?
        
        let errorReason = (error.domain, error.code, error.userInfo[OperationConditionKey] as? String)
        
        // These are examples of errors for which we might choose to display an error to the user
        let failedReachability = (OperationErrorDomain, OperationErrorCode.conditionFailed, ReachabilityCondition.name)
        
        let failedJSON = (NSCocoaErrorDomain, NSPropertyListReadCorruptError, nil as String?)
        
        let failedServerError = (OperationErrorDomain, OperationErrorCode.executionFailed.rawValue, nil as String?)
        
        let failedOther = (NSURLErrorDomain, -1200, nil as String?)
        
        switch errorReason {
        case failedReachability:
            // We failed because the network isn't reachable.
            let hostURL = error.userInfo[ReachabilityCondition.hostKey] as! NSURL
            
            alert = AlertOperation()
            alert?.title = "Unable to Connect"
            alert?.message = "Cannot connect to \(hostURL.host!). Make sure your device is connected to the internet and try again."
            
        case failedJSON:
            // We failed because the JSON was malformed.
            alert = AlertOperation()
            alert?.title = "Unable to Download"
            alert?.message = "Cannot parse \(name) results. Try again later."
            
        case failedServerError:
            guard let desiredMIMEType = error.userInfo[mimeTypeDesiredKey] as? [String],
                  let returnedMIMEType = error.userInfo[mimeTypeReturnedKey] as? String ,
                  !desiredMIMEType.contains( returnedMIMEType ) else {
            
                alert = AlertOperation()
                    alert?.title = "Unknown error"
                    alert?.message = "Don't know how we got here. Need some serious debugging pronto!"
                    produceOperation( alert! )
                return
            }

            if htmlMIMEType == returnedMIMEType || textMIMEType == returnedMIMEType {
                
                html = HTMLPageOperation()
                if let name = name {
                    html?.operationName = name
                }
                if let data = error.userInfo[dataKey] as? Data {
                    html?.data = data
                } else if let url = error.userInfo[streamKey] as? URL {
                    html?.url = url
                }
            }

        case failedOther:
            alert = AlertOperation()
            alert?.title = "Not Logged In to WiFi"
            alert?.message = "Please log on to the WiFi access point."
            
        default:
//            alert = AlertOperation()
//            alert?.title = "Unknown Error"
//            alert?.message = String( error.userInfo )
            break
        }
        
        if let alert = alert {
            produceOperation(alert)
            hasProducedAlert = true
        }
        
        if let html = html {
            
            html.operationError = error
            produceOperation( html )
            hasProducedAlert = true
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
