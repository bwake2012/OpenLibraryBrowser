//
//  LoginOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 12/11/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

import PSOperations

class LoginOperation: PSOperations.GroupOperation {
    // MARK: Properties
    
    let postOperation: LoginPostOperation
    
    init( completionHandler: @escaping (Void) -> Void ) {
        
        postOperation = LoginPostOperation()
        let finishOperation = PSBlockOperation { completionHandler() }
        
        // These operations must be executed in order
        finishOperation.addDependency( postOperation )
        
        super.init( operations: [postOperation, finishOperation] )
        
        //        queuePriority = .Low
        
        addCondition( MutuallyExclusive<BookGetOperation>() )
        
        name = "Get book"
    }
    
    override func operationDidFinish(_ operation: Foundation.Operation, withErrors errors: [NSError]) {

        if let firstError = errors.first, ( operation === postOperation ) {

            produceAlert( firstError )
        }
    }
}
