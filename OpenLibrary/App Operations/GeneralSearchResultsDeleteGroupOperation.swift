//  GeneralSearchResultsDeleteGroupOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import CoreData

// import BNRCoreDataStack
import PSOperations

/// A composite `Operation` to both download and parse General search result data.
class GeneralSearchResultsDeleteGroupOperation: GroupOperation {
    // MARK: Properties
    
    var deleteOperation: GeneralSearchResultsDeleteOperation?
    let finishOperation: PSBlockOperation
   
//    private var hasProducedAlert = false
    
    fileprivate let dataStack: OLDataStack
    
    /**
        - parameter context: The `NSManagedObjectContext` into which the parsed
                             General query results will be imported.

        - parameter completionHandler: The handler to call after downloading and
                                       parsing are complete. This handler will be
                                       invoked on an arbitrary queue.
    */
    init( dataStack: OLDataStack, completionHandler: @escaping () -> Void ) {

        self.dataStack = dataStack

        /*
            This operation has one child operation:
            operation to delete the existing contents of the Core Data store
        */
        deleteOperation = GeneralSearchResultsDeleteOperation( dataStack: dataStack )
        finishOperation = PSBlockOperation { completionHandler() }
        
        // These operations must be executed in order
        finishOperation.addDependency( deleteOperation! )
        
        let operations: [PSOperation] = [deleteOperation!, finishOperation]
        super.init( operations: operations )

        addCondition( MutuallyExclusive<GeneralSearchResultsDeleteGroupOperation>() )
        
        queuePriority = .high
        
        name = "General Search Delete"
    }
    
    override func operationDidFinish(_ operation: Foundation.Operation, withErrors errors: [NSError]) {
        if let firstError = errors.first {

            if operation === deleteOperation {
                produceAlert(firstError)
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
