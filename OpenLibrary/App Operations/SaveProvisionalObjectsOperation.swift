//  SaveProvisionalObjectsOperation
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/2/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import CoreData

import BNRCoreDataStack
import PSOperations

/// A composite `Operation` to both download and parse author search result data.
class SaveProvisionalObjectsOperation: GroupOperation {
    // MARK: Properties
    
    let saveOperation: SaveObjectsOperation
   
//    private var hasProducedAlert = false
    
    /**
        - parameter context: The `NSManagedObjectContext` into which the parsed
                             author query results will be imported.

        - parameter completionHandler: The handler to call after downloading and
                                       parsing are complete. This handler will be
                                       invoked on an arbitrary queue.
    */
    init( searchResult: OLGeneralSearchResult, coreDataStack: CoreDataStack, completionHandler: Void -> Void ) {
        
        saveOperation =
            SaveObjectsOperation( objectID: searchResult.objectID, coreDataStack: coreDataStack )
        let finishOperation = NSBlockOperation( block: completionHandler )
        
        // These operations must be executed in order
        finishOperation.addDependency( saveOperation )
        
        super.init( operations: [saveOperation, finishOperation] )
        
        queuePriority = .Normal
        
        addCondition( MutuallyExclusive< SaveProvisionalObjectsOperation >() )

        name = "Save Provisional Objects"
    }
    
    override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
        
        if let firstError = errors.first where (operation === saveOperation) {
            
            produceAlert( firstError )
        }
    }
    
}

