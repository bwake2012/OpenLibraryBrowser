//
//  OLQueryCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/7/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

import BNRCoreDataStack

class OLQueryCoordinator: NSObject {

    let operationQueue: OperationQueue
    let coreDataStack: CoreDataStack
    
    init( operationQueue: OperationQueue, coreDataStack: CoreDataStack ) {
        
        self.operationQueue = operationQueue
        self.coreDataStack = coreDataStack
    }
}
