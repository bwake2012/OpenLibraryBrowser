//
//  Operation+ValidateMIMEType.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 8/23/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

import ObjectiveC

import PSOperations

let dataKey   = "hostData"
let streamKey = "hostStream"
let mimeTypeDesiredKey  = "MIMETypeDesired"
let mimeTypeReturnedKey = "MIMETypeReturned"

extension Operation {
    
    func validateDataMIMEType( mimeType: String, response: NSHTTPURLResponse?, data: NSData? ) -> NSError? {
        
        guard let response = response, responseMIMEType = response.MIMEType else {
            
            return nil
        }
        
        if mimeType != response.MIMEType {
            
//            let className = NSStringFromClass(self.dynamicType).componentsSeparatedByString(".").last!
            
            var userInfo: [NSObject: AnyObject] =
                [
//                    OperationConditionKey: className,
                    mimeTypeDesiredKey: mimeType,
                    mimeTypeReturnedKey: responseMIMEType
            ]
            if let data = data {
                
                userInfo[dataKey] = data
            }
            
            return NSError( code: OperationErrorCode.ExecutionFailed, userInfo: userInfo )
        }
        
        return nil
    }

    func validateStreamMIMEType( mimeType: String, response: NSHTTPURLResponse?, url: NSURL? ) -> NSError? {
        
        guard let response = response, responseMIMEType = response.MIMEType else {
            
            return nil
        }
        
        if mimeType != responseMIMEType {
            
//            let className = NSStringFromClass( self.dynamicType ).componentsSeparatedByString(".").last!
            
            var userInfo: [NSObject: AnyObject] =
                [
//                    OperationConditionKey: className,
                    mimeTypeDesiredKey: mimeType,
                    mimeTypeReturnedKey: responseMIMEType
                ]
            if let url = url {
                
                userInfo[streamKey] = url
            }
            
            return NSError( code: OperationErrorCode.ExecutionFailed, userInfo: userInfo )
        }
        
        return nil
    }
}