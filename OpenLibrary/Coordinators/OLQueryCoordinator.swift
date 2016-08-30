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
    
    private static var thumbnailCache = NSCache()

    private static var reachability: Reachability?
    private static var viewControllerStack = [UIViewController]()
    
    private static var dateFormatter: NSDateFormatter?

    // MARK: Instance variables
    var deletedSectionIndexes = NSMutableIndexSet()
    var insertedSectionIndexes = NSMutableIndexSet()
    
    var deletedRowIndexPaths: [NSIndexPath] = []
    var insertedRowIndexPaths: [NSIndexPath] = []
    var updatedRowIndexPaths: [NSIndexPath] = []
    
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

        dispatch_async(dispatch_get_main_queue()) {
                
            if let refreshControl = refreshControl {
                
                if nil == OLQueryCoordinator.dateFormatter {
                    
                    OLQueryCoordinator.dateFormatter = NSDateFormatter()
                
                    OLQueryCoordinator.dateFormatter?.dateFormat = "MMM d, h:mm a"
                }
                
                if let dateFormatter = OLQueryCoordinator.dateFormatter {
                
                    let lastUpdate = "Last updated on \( dateFormatter.stringFromDate( NSDate() ) )"
                    
                    refreshControl.attributedTitle = NSAttributedString( string: lastUpdate )
                }
                refreshControl.endRefreshing()
            }
        }
    }

    func updateTableFooter( tableView: UITableView?, highWaterMark: Int, numFound: Int, text: String = "" ) -> Void {
        
        dispatch_async( dispatch_get_main_queue() ) {
            
            [weak tableView] in
            
            if let tableView = tableView {
                if let footer = tableView.tableFooterView as? OLTableViewHeaderFooterView {
                    
                    if !text.isEmpty {
                        footer.footerLabel.text = text
                    } else if 0 == highWaterMark && 0 == numFound {
                        footer.footerLabel.text = "No results found."
                    } else {
                        footer.footerLabel.text = "\(highWaterMark) of \(numFound)"
                    }
                }
            }
        }
    }
    
    func cachedImage( localURL: NSURL ) -> UIImage? {
        
        guard let cacheKey = localURL.lastPathComponent else {
            return nil
        }
        
        if let image = OLQueryCoordinator.thumbnailCache.objectForKey( cacheKey ) as? UIImage {
            
            return image
            
        } else if localURL.fileURL {
            
            if let data = NSData( contentsOfURL: localURL ) {
                
                if let image = UIImage( data: data ) {

                    OLQueryCoordinator.thumbnailCache.setObject( image, forKey: cacheKey )
                    
                    return image
                }
            }
        }
        
        return nil
    }
    
    func preloadThumbnail( object: OLManagedObject ) -> Void {
        
        if object.hasImage {
            
            let localURL = object.localURL( "S" )
            
            dispatch_async( dispatch_queue_create( "preloadThumbnail", nil ) ) {
                
                if nil != self.cachedImage( localURL ) {
                    
                    return
                    
                } else {
                    
                    let url = localURL
                    let imageGetOperation =
                        ImageGetOperation( numberID: object.firstImageID, imageKeyName: "id", localURL: url, size: "S", type: object.imageType ) {
                            
                            self.cachedImage( localURL )                }
                    
                    imageGetOperation.userInitiated = true
                    self.operationQueue.addOperation( imageGetOperation )
                }
            }
        }
    }
    
    func displayThumbnail( object: OLManagedObject, tableView: UITableView, indexPath: NSIndexPath ) {
        
        assert( NSThread.isMainThread() )
        //        print( "\(object.title) \(object.hasImage ? "has" : "has no") cover image")
        
        guard let cell = tableView.cellForRowAtIndexPath( indexPath ) as? OLTableViewCell else {
            return
        }

        if object.hasImage {
            
            let localURL = object.localURL( "S" )
            if let image = cachedImage( localURL ) {
                
                cell.displayImage( localURL, image: image )
                
            } else {
                
                let url = localURL
                let imageGetOperation =
                    ImageGetOperation( numberID: object.firstImageID, imageKeyName: "id", localURL: url, size: "S", type: object.imageType ) {
                        
                        if let image = self.cachedImage( localURL ) {
                            
                            dispatch_async( dispatch_get_main_queue() ) {
                                    
                                guard let cell = tableView.cellForRowAtIndexPath( indexPath ) as? OLTableViewCell else {
                                    return
                                }
                                    
                                cell.displayImage( url, image: image )
                            }
                        }
                }
                
                imageGetOperation.userInitiated = true
                operationQueue.addOperation( imageGetOperation )
            }
        }
    }

    func displayThumbnail( object: OLManagedObject, cell: OLTableViewCell ) {
        
        assert( NSThread.isMainThread() )
        //        print( "\(object.title) \(object.hasImage ? "has" : "has no") cover image")
        if object.hasImage {
            
            let localURL = object.localURL( "S" )
            if let image = cachedImage( localURL ) {
                
                cell.displayImage( localURL, image: image )
                
            } else {
                
                let url = localURL
                let imageGetOperation =
                    ImageGetOperation( numberID: object.firstImageID, imageKeyName: "id", localURL: url, size: "S", type: object.imageType ) {
                        
                        if let image = self.cachedImage( localURL ) {
                            
                            dispatch_async( dispatch_get_main_queue() ) {
                                
                                cell.displayImage( url, image: image )
                            }
                        }
                }
                
                imageGetOperation.userInitiated = true
                operationQueue.addOperation( imageGetOperation )
            }
        }
    }

}
