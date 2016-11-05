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
let hostURLKey = "hostURL"

extension PSOperation {
    
    func validateDataMIMEType( _ mimeTypes: [String], response: HTTPURLResponse?, data: Data? ) -> NSError? {
        
        guard let response = response, let responseMIMEType = response.mimeType else {
            
            return nil
        }
        
        if !mimeTypes.contains( responseMIMEType ) {
            
//            let className = NSStringFromClass(self.dynamicType).componentsSeparatedByString(".").last!
            
            var userInfo: [AnyHashable: Any] =
                [
//                    OperationConditionKey: className,
                    mimeTypeDesiredKey: mimeTypes,
                    mimeTypeReturnedKey: responseMIMEType
            ]
            if let data = data {
                
                userInfo[dataKey] = data
            }
            
            return NSError( code: OperationErrorCode.executionFailed, userInfo: userInfo as [NSObject : AnyObject]? )
        }
        
        return nil
    }

    func validateStreamMIMEType( _ mimeTypes: [String], response: HTTPURLResponse?, url: URL? ) -> NSError? {
        
        guard let response = response, let responseMIMEType = response.mimeType else {
            
            return nil
        }
        
        if !mimeTypes.contains( responseMIMEType ) {
        
            var userInfo: [AnyHashable: Any] =
                [
    //                    OperationConditionKey: className,
                    mimeTypeDesiredKey: mimeTypes,
                    mimeTypeReturnedKey: responseMIMEType
                ]
            if let url = url {
                
                userInfo[streamKey] = url
            }
            
            return NSError( code: OperationErrorCode.executionFailed, userInfo: userInfo as [NSObject : AnyObject]? )
        }
        
        return nil
    }
}
