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
    
    private static var previousNetStatus: Reachability.NetworkStatus = .ReachableViaWiFi
    
    private static var thumbnailCache = NSCache()
    private class CacheData {
        
        var fetchInProgress: Bool {
            
            return nil == image
        }
        var image: UIImage?
        
        init( image: UIImage? ) {
            
            self.image = image
        }
    }

    private static var reachability: Reachability?
    private static var queryCoordinatorCount: Int = 0
    
    private static var dateFormatter: NSDateFormatter?

    // MARK: Instance variables
    var deletedSectionIndexes = NSMutableIndexSet()
    var insertedSectionIndexes = NSMutableIndexSet()
    
    var deletedRowIndexPaths: [NSIndexPath] = []
    var insertedRowIndexPaths: [NSIndexPath] = []
    var updatedRowIndexPaths: [NSIndexPath] = []
    
    let operationQueue: OperationQueue
    let coreDataStack: CoreDataStack
    
    private var reachability: Reachability {
        
        if nil == OLQueryCoordinator.reachability {
            
            do {
                OLQueryCoordinator.reachability = try Reachability( hostname: "openlibrary.org" )
                
                if let reachability = OLQueryCoordinator.reachability {
                    
                    reachability.whenReachable = {
                        
                        reachability in
                        
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
                    reachability.whenUnreachable = {
                        
                        reachability in
                        
                        // this is called on a background thread, but UI updates must
                        // be on the main thread, like this:
                        dispatch_async(dispatch_get_main_queue()) {
                            print("Not reachable")
                        }
                    }
                    
                    do {
                        try reachability.startNotifier()
                    } catch {
                        fatalError( "Unable to start network reachability notifier.")
                    }
                }
                
            } catch {
                fatalError( "Unable to create network reachability monitor.")
            }
        }
        
        return OLQueryCoordinator.reachability!
    }
    
    init( operationQueue: OperationQueue, coreDataStack: CoreDataStack, viewController: UIViewController ) {
        
        OLQueryCoordinator.queryCoordinatorCount += 1
        self.operationQueue = operationQueue
        self.coreDataStack = coreDataStack
    }
    
    deinit {

        OLQueryCoordinator.queryCoordinatorCount -= 1
        if 0 == OLQueryCoordinator.queryCoordinatorCount {
            
            if let reachability = OLQueryCoordinator.reachability {
                
                reachability.stopNotifier()
                
                OLQueryCoordinator.reachability = nil
            }
        }
    }
    
    func libraryIsReachable( tattle tattle: Bool = false ) -> Bool {
        
        var isReachable = false
        
        let newStatus = reachability.currentReachabilityStatus

        let oldStatus = OLQueryCoordinator.previousNetStatus
        OLQueryCoordinator.previousNetStatus = newStatus
        
        switch newStatus {
        
            case .NotReachable:
                if tattle && newStatus != oldStatus {
                    showNetworkUnreachableAlert( oldStatus, newStatus: newStatus )
                }
                break
            case .ReachableViaWWAN:
                isReachable = true
                break
            case .ReachableViaWiFi:
                isReachable = true
                break
        }
        
        return isReachable
    }

    func showNetworkUnreachableAlert(
                oldStatus: Reachability.NetworkStatus,
                newStatus: Reachability.NetworkStatus
            ) {
        
        dispatch_async( dispatch_get_main_queue() ) {

            guard let presentationContext = UIApplication.topViewController() else {

                return
            }
            
            let alertController =
                UIAlertController(
                        title: "Sad Face Emoji!",
                        message: "Cell data permission was not authorized. Please enable it in Settings to continue.",
                        preferredStyle: .Alert
                    )
            
            let settingsAction =
                UIAlertAction( title: "Settings", style: .Default ) {
                    
                    (alertAction) in
                    
                        // THIS IS WHERE THE MAGIC HAPPENS!!!!
                        if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                            UIApplication.sharedApplication().openURL(appSettings)
                        }
                    }
            alertController.addAction( settingsAction )
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction( cancelAction )
            
            presentationContext.presentViewController( alertController, animated: true, completion: nil )
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
    
    private func cachedData( cacheKey: String ) -> CacheData? {
        
        return OLQueryCoordinator.thumbnailCache.objectForKey( cacheKey ) as? CacheData
    }
    
    private func cachedImage( localURL: NSURL ) -> UIImage? {
        
        guard localURL.fileURL else {
            
            return nil
        }
        
        guard let cacheKey = localURL.lastPathComponent else {
            return nil
        }
        
        guard let cacheData = cachedData( cacheKey ) else {
            
            return nil
        }
        
        if let image = cacheData.image {
            
            return image
            
        } else if let data = NSData( contentsOfURL: localURL ) {
                
            if let image = UIImage( data: data ) {

                OLQueryCoordinator.thumbnailCache.setObject( CacheData( image: image ), forKey: cacheKey )
                
                return image
            }
        }
        
        return nil
    }
    
    private func displayThumbnailImage(
                    url: NSURL,
                    image: UIImage,
                    cell: OLTableViewCell?
                ) {
        
        dispatch_async( dispatch_get_main_queue() ) {
            
            [weak cell] in
            
            if let cell = cell {
                
                cell.displayImage( url, image: image )
            }
        }
        
    }
    
    func enqueueImageFetch( url: NSURL, imageID: Int, imageType: String, cell: OLTableViewCell ) {
        
        guard libraryIsReachable() else {
            return
        }
        
        let imageGetOperation =
            ImageGetOperation( numberID: imageID, imageKeyName: "id", localURL: url, size: "S", type: imageType ) {
                
                [weak self, weak cell] in
                
                if let strongSelf = self, cell = cell {
                    
                    if let image = strongSelf.cachedImage( url ) {
                        
                        strongSelf.displayThumbnailImage( url, image: image, cell: cell )
                    }
                }
        }
        
        imageGetOperation.userInitiated = true
        operationQueue.addOperation( imageGetOperation )
    }
    
    func displayThumbnail( object: OLManagedObject, cell: OLTableViewCell? ) {
        
        guard object.hasImage else {
            return
        }
        
        let url = object.localURL( "S" )
        guard let cacheKey = url.lastPathComponent else {
            assert( false )
            return
        }
        
        let cacheData = cachedData( cacheKey )
        let image: UIImage? = cacheData?.image
        if let image = image {
            
            if let cell = cell {
                
                cell.displayImage( url, image: image )
            }
            
        } else if nil == cacheData {
            
            OLQueryCoordinator.thumbnailCache.setObject( CacheData( image: image ), forKey: cacheKey )
            
            let imageID = object.firstImageID
            let imageType = object.imageType
            dispatch_async( dispatch_queue_create( "preloadThumbnail", nil ) ) {
                
                [weak self, weak cell] in

                if let strongSelf = self, cell = cell {

                    if let image = strongSelf.cachedImage( url ) {
                        
                        strongSelf.displayThumbnailImage(
                                url,
                                image: image,
                                cell: cell
                            )
                        
                    } else {
                        
                        strongSelf.enqueueImageFetch(
                                url,
                                imageID: imageID,
                                imageType: imageType,
                                cell: cell
                            )
                    }
                }
            }
        }
    }
}
