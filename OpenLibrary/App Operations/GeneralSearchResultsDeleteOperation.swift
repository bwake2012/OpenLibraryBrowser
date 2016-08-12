//
//  GeneralSearchResultsDeleteOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/10/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

import BNRCoreDataStack
import PSOperations

class GeneralSearchResultsDeleteOperation: Operation {
    
    let deleteContext: NSManagedObjectContext
    
    init( coreDataStack: CoreDataStack ) {
        
        self.deleteContext = coreDataStack.newChildContext()
    }
    
    override func execute() {
        
        let entityName = OLGeneralSearchResult.entityName
        let fetchRequest = NSFetchRequest( entityName: entityName )
        let deleteRequest = NSBatchDeleteRequest( fetchRequest: fetchRequest )
        deleteRequest.resultType = .ResultTypeObjectIDs
        
        do {

            try deleteContext.persistentStoreCoordinator?.executeRequest(
                        deleteRequest, withContext: self.deleteContext
                    )
            
            try deleteContext.saveContextAndWait()
            
        } catch let error as NSError {
            
            // TODO: handle the error
            finishWithError( error )
        }
        
        finish()
    }
}
