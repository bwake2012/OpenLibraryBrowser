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
import PSOperations

class AuthorSearchResultsDeleteOperation: PSOperation {
    
    let deleteContext: NSManagedObjectContext
    
    init( coreDataStack: OLDataStack ) {
        
        self.deleteContext = coreDataStack.newChildContext( name: "AuthorSearchResultsDelete Context" )
    }
    
    override func execute() {
        
        let fetchRequest = OLAuthorSearchResult.buildFetchRequest()
        let deleteRequest = NSBatchDeleteRequest( fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult> )
        
        do {

            try deleteContext.persistentStoreCoordinator?.execute( deleteRequest, with: self.deleteContext )

        } catch let error as NSError {
            
            // TODO: handle the error
            finishWithError( error )
        }
        
        finish()
    }
}
