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
import BRYXBanner

class OLQueryCoordinator: NSObject {

    private static var previousNetStatus: Reachability.NetworkStatus = .ReachableViaWiFi
    private static var previousDescription: String = ""
    
    private static var thumbnailCache = NSCache()
    private class CacheData {
        
        var image: UIImage?
        let date = NSDate()
        var fetchInProgress: Bool {
            
            return nil == image && date.timeIntervalSinceNow < 10.0
        }
        
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
                OLQueryCoordinator.reachability =
                    try Reachability( hostname: "openlibrary.org" )
                
                if let reachability = OLQueryCoordinator.reachability {
                    
                    OLQueryCoordinator.previousDescription = reachability.description

                    reachability.whenReachable = reachable
                    reachability.whenUnreachable = unreachable
                    
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
    
    func libraryIsReachable( tattle tattle: Bool = false, keepQuiet: Bool = false ) -> Bool {
        
        var isReachable = false
        
        let newStatus = reachability.currentReachabilityStatus

        let oldStatus = OLQueryCoordinator.previousNetStatus
        OLQueryCoordinator.previousNetStatus = newStatus
        
        switch newStatus {
        
            case .NotReachable:
                if !keepQuiet && ( tattle || ( newStatus != oldStatus ) ) {
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
                        title: "Could not Reach OpenLibrary",
                        message: "Either you have not signed on to WiFi or you have not given this app permission to use cell data. Please enable it in Settings to continue.",
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
    
    func updateTableHeader( tableView: UITableView?, text: String = "" ) {
        
        dispatch_async( dispatch_get_main_queue() ) {
            
            if let tableView = tableView {
                
                if text.isEmpty {
                    
                    tableView.tableHeaderView = nil
                
                } else {
                    
                    var tableHeaderView: OLTableViewHeaderFooterView? = tableView.tableHeaderView as? OLTableViewHeaderFooterView
                    if nil == tableHeaderView {
                        
                        tableHeaderView = OLTableViewHeaderFooterView.createFromNib() as? OLTableViewHeaderFooterView
                        tableView.tableHeaderView = tableHeaderView

                    }
                    
                    if let tableHeaderView = tableHeaderView {
                        
                        tableHeaderView.footerLabel.text = text
                    }
                }
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
                        footer.footerLabel.text =
                            "\(highWaterMark) of \(-1 == numFound ? "Unknown" : String(numFound))"
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
                    cell: OLCell
                ) {
        
        dispatch_async( dispatch_get_main_queue() ) {
            
            [weak cell] in
            
            if let cell = cell {
                
                cell.displayImage( url, image: image )
            }
        }
    }
    
    private func enqueueImageFetch( url: NSURL, imageID: Int, imageType: String, cell: OLCell ) {
        
        guard libraryIsReachable( keepQuiet: true ) else {
            return
        }
        
        let pointSize = cell.imageSize()
        let imageGetOperation =
            ImageGetOperation( numberID: imageID, imageKeyName: "id", localURL: url, size: "M", type: imageType, displayPointSize: pointSize ) {
                
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
    
    func displayThumbnail( object: OLManagedObject, cell: OLCell? ) -> Bool {
        
        guard object.hasImage else {
            return false
        }
        
        let url = object.localURL( "S" )
        guard let cacheKey = url.lastPathComponent else {
            assert( false )
            return false
        }
        
        // is there an entry in the cache?
        if let cacheData = cachedData( cacheKey ) {
            
            // is there an image on the entry?
            if let image = cacheData.image {
            
                if let cell = cell {
                    
                    cell.displayImage( url, image: image )
                    return true
                }

            // otherwise, is there an image fetch in progress?
            } else if cacheData.fetchInProgress {

                return true
            }
        }

        OLQueryCoordinator.thumbnailCache.setObject( CacheData( image: nil ), forKey: cacheKey )

        // retrieve the thumbnail from openlibrary.org
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
        
        return true
    }
    
    // MARK: Reachability delegates

    private func reachable( reachability: Reachability ) {
        
        let currentDescription = reachability.description
        if currentDescription != OLQueryCoordinator.previousDescription {
            
            OLQueryCoordinator.previousDescription = currentDescription
        
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            dispatch_async(dispatch_get_main_queue()) {
                let reachMessage = "Reachable"
                let banner =
                    Banner(
                        title: "Network Access",
                        subtitle: "OpenLibrary " + reachMessage,
                        image: UIImage(named: "777-thumbs-up-selected-white"),
                        backgroundColor:
                        UIColor(
                            red:48.00/255.0,
                            green:174.0/255.0,
                            blue:51.5/255.0,
                            alpha:1.000
                        )
                )
                banner.dismissesOnTap = true
                banner.show(duration: 3.0)
            }
        }
    }
    
    private func unreachable( reachability: Reachability ) {
        
        OLQueryCoordinator.previousDescription = reachability.description

        // this is called on a background thread, but UI updates must
        // be on the main thread, like this:
        dispatch_async(dispatch_get_main_queue()) {
            let reachMessage = "Not Reachable"
            let banner =
                Banner(
                    title: "Network Access",
                    subtitle: "OpenLibrary " + reachMessage,
                    image: UIImage(named: "778-thumbs-down-selected-white"),
                    backgroundColor:
                    UIColor(
                        red:174.00/255.0,
                        green:48.0/255.0,
                        blue:51.5/255.0,
                        alpha:1.000
                    )
            )
            banner.dismissesOnTap = true
            banner.show(duration: 3.0)
        }
    }

}
