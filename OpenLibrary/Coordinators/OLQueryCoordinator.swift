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
    
    func refreshComplete( refreshControl: UIRefreshControl? ) {

        if let refreshControl = refreshControl {
            
            let dateFormatter = NSDateFormatter()
            
            dateFormatter.dateFormat = "MMM d, h:mm a"
            
            let lastUpdate = "Last updated on \( dateFormatter.stringFromDate( NSDate() ) )"
            
            refreshControl.attributedTitle = NSAttributedString( string: lastUpdate )
            refreshControl.endRefreshing()
        }
    }
}
