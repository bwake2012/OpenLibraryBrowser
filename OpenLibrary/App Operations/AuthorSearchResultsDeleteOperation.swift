//
//  AuthorSearchResultsDeleteOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/25/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

import BNRCoreDataStack

class AuthorSearchResultsDeleteOperation: Operation {
    
    let deleteContext: NSManagedObjectContext
    
    init( coreDataStack: CoreDataStack ) {
        
        self.deleteContext = coreDataStack.newBackgroundWorkerMOC()
    }
    
    deinit {
        
        print( "\(self.dynamicType.description()) deinit" )
    }
    
    override func execute() {
        
        let fetchRequest = NSFetchRequest( entityName: OLAuthorSearchResult.entityName )
        let deleteRequest = NSBatchDeleteRequest( fetchRequest: fetchRequest )
        
        do {

            try deleteContext.persistentStoreCoordinator?.executeRequest( deleteRequest, withContext: self.deleteContext )

        } catch let error as NSError {
            
            // TODO: handle the error
            finishWithError( error )
        }
        
        finish()
    }
}