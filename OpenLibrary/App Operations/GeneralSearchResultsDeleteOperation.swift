//
//  GeneralSearchResultsDeleteOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/10/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

//import BNRCoreDataStack
import PSOperations

class GeneralSearchResultsDeleteOperation: PSOperation {
    
    typealias OLGeneralSearchResultFetchRequest = NSFetchRequest< OLGeneralSearchResult >
    
    let deleteContext: NSManagedObjectContext
    
    init( dataStack: OLDataStack ) {
        
        self.deleteContext = dataStack.newChildContext( name: "GeneralSearchResultsDelete Context" )
    }
    
    override func execute() {
        
        let fetchRequest: NSFetchRequest< OLGeneralSearchResult > = OLGeneralSearchResult.buildFetchRequest()

        let deleteRequest = NSBatchDeleteRequest( fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult> )
        deleteRequest.resultType = .resultTypeObjectIDs
        
        do {

            try deleteContext.persistentStoreCoordinator?.execute(
                        deleteRequest, with: self.deleteContext
                    )
            
            try deleteContext.save()
            
        } catch let error as NSError {
            
            // TODO: handle the error
            finishWithError( error )
        }
        
        finish()
    }
}
