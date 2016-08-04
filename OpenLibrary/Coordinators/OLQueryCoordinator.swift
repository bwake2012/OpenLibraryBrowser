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
import ReachabilitySwift
import PSOperations

class OLQueryCoordinator: NSObject {

    private static var reachability: Reachability?
    private static var viewControllerStack = [UIViewController]()

    // MARK: Instance variables
    let operationQueue: OperationQueue
    let coreDataStack: CoreDataStack

    init( operationQueue: OperationQueue, coreDataStack: CoreDataStack, viewController: UIViewController ) {
        
        OLQueryCoordinator.viewControllerStack.append( viewController )
        
        self.operationQueue = operationQueue
        self.coreDataStack = coreDataStack
        
        if nil == OLQueryCoordinator.reachability {
            
            do {
                OLQueryCoordinator.reachability = try Reachability( hostname: "openlibrary.org" )
                
                if let reachability = OLQueryCoordinator.reachability {
                    
                    reachability.whenReachable = { reachability in
                        // this is called on a background thread, but UI updates must
                        // be on the main thread, like this:
                        dispatch_async(dispatch_get_main_queue()) {
                            if reachability.isReachableViaWiFi() {
                                print("Reachable via WiFi")
                            } else if reachability.isReachableViaWWAN() {
                                print("Reachable via Cellular")
                            } else {
                                print("Reachable via unknown method")
                            }
                        }
                    }
                    reachability.whenUnreachable = { reachability in
                        // this is called on a background thread, but UI updates must
                        // be on the main thread, like this:
                        dispatch_async(dispatch_get_main_queue()) {
                            print("Not reachable")
                        }
                    }
                    
                    do {
                        try reachability.startNotifier()
                    } catch {
                        print("Unable to start notifier")
                    }
                }
                
            } catch {
                print("Unable to create Reachability")
            }
        }
        
    }
    
    deinit {

        OLQueryCoordinator.viewControllerStack.removeLast()
        if OLQueryCoordinator.viewControllerStack.isEmpty {
            
            if let reachability = OLQueryCoordinator.reachability {
                
                reachability.stopNotifier()
                
                OLQueryCoordinator.reachability = nil
            }
        }
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
