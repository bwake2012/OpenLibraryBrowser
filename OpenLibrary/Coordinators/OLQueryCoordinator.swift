//
//  OLQueryCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/7/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

//import BNRCoreDataStack
import Reachability
import PSOperations
import BRYXBanner

class OLQueryCoordinator: NSObject {

    fileprivate static var previousNetStatus: Reachability.Connection = .wifi
    fileprivate static var previousDescription: String = ""
    
    fileprivate static var thumbnailCache = NSCache< NSString, CacheData >()
    fileprivate class CacheData {
        
        var image: UIImage?
        let date = Date()
        var fetchInProgress: Bool {
            
            return nil == image && date.timeIntervalSinceNow < 10.0
        }
        
        init( image: UIImage? ) {
            
            self.image = image
        }
    }

    fileprivate static var reachability: Reachability?
    fileprivate static var queryCoordinatorCount: Int = 0
    
    fileprivate static var dateFormatter: DateFormatter?

    // MARK: Instance variables
    var deletedSectionIndexes = NSMutableIndexSet()
    var insertedSectionIndexes = NSMutableIndexSet()
    
    var deletedRowIndexPaths: [IndexPath] = []
    var insertedRowIndexPaths: [IndexPath] = []
    var updatedRowIndexPaths: [IndexPath] = []
    
    let operationQueue: PSOperationQueue
    let dataStack: OLDataStack
    
    fileprivate var reachability: Reachability {
        
        if nil == OLQueryCoordinator.reachability {
            
            OLQueryCoordinator.reachability =
                Reachability( hostname: "openlibrary.org" )
            
            if let reachability = OLQueryCoordinator.reachability {
                
                OLQueryCoordinator.previousDescription = reachability.description

                reachability.whenReachable = reachable
                reachability.whenUnreachable = unreachable
                
                do {
                    try reachability.startNotifier()
                } catch {
                    fatalError( "Unable to start network reachability notifier." )
                }
            } else {
                fatalError( "Unable to create network reachability monitor.")
            }
            
        }
        
        return OLQueryCoordinator.reachability!
    }
    
    init( operationQueue: PSOperationQueue, dataStack: OLDataStack, viewController: UIViewController ) {
        
        OLQueryCoordinator.queryCoordinatorCount += 1
        self.operationQueue = operationQueue
        self.dataStack = dataStack
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
    
    func libraryIsReachable( tattle: Bool = false, keepQuiet: Bool = false ) -> Bool {
        
        var isReachable = false
        
        let newStatus = reachability.connection

        let oldStatus = OLQueryCoordinator.previousNetStatus
        OLQueryCoordinator.previousNetStatus = newStatus
        
        switch newStatus {
        
            case .none:
                if !keepQuiet && ( tattle || ( newStatus != oldStatus ) ) {
                    showNetworkUnreachableAlert( oldStatus, newStatus: newStatus )
                }
                break
            case .cellular:
                isReachable = true
                break
            case .wifi:
                isReachable = true
                break
        }
        
        return isReachable
    }

    func showNetworkUnreachableAlert(
        _ oldStatus: Reachability.Connection,
        newStatus: Reachability.Connection
            ) {
        
        DispatchQueue.main.async {

            guard let presentationContext = UIApplication.topViewController() else {

                return
            }
            
            let alertController =
                UIAlertController(
                        title: NSLocalizedString( "Could not Reach OpenLibrary", comment: "" ),
                        message: NSLocalizedString( "need-wan-access", comment: "" ),
                        preferredStyle: .alert
                    )
            
            let settingsAction =
                UIAlertAction( title: NSLocalizedString( "Settings", comment: "" ), style: .default ) {
                    
                    (alertAction) in
                    
                        // THIS IS WHERE THE MAGIC HAPPENS!!!!
                        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(appSettings)
                        }
                    }
            alertController.addAction( settingsAction )
            
            let cancelAction = UIAlertAction(title: NSLocalizedString( "Cancel", comment: "" ), style: .cancel, handler: nil)
            alertController.addAction( cancelAction )
            
            presentationContext.present( alertController, animated: true, completion: nil )
        }
    }
    
    func refreshComplete( _ refreshControl: UIRefreshControl? ) {

        DispatchQueue.main.async {
                
            if let refreshControl = refreshControl {
                
                if nil == OLQueryCoordinator.dateFormatter {
                    
                    OLQueryCoordinator.dateFormatter = DateFormatter()
                
                    OLQueryCoordinator.dateFormatter?.dateStyle = .medium
                }
                
                if let dateFormatter = OLQueryCoordinator.dateFormatter {
                
                    let lastUpdate = NSLocalizedString( "Last updated on ", comment: "" ) + "\( dateFormatter.string( from: Date() ) )"
                    
                    refreshControl.attributedTitle = NSAttributedString( string: lastUpdate )
                }
                refreshControl.endRefreshing()
            }
        }
    }
    
    func updateTableHeader( _ tableView: UITableView?, text: String = "" ) {
        
        DispatchQueue.main.async {
            
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

    func updateTableFooter( _ tableView: UITableView?, highWaterMark: Int, numFound: Int, text: String = "" ) -> Void {
        
        DispatchQueue.main.async {
            
            [weak tableView] in
            
            if let tableView = tableView {
                if let footer = tableView.tableFooterView as? OLTableViewHeaderFooterView {
                    
                    if !text.isEmpty {
                        footer.footerLabel.text = text
                    } else if 0 == highWaterMark && 0 == numFound {
                        footer.footerLabel.text =
                            NSLocalizedString(
                                    "No results found.",
                                    comment: "the search on openlibrary.org returned no results"
                                )
                    } else {
                        var foundString = ""
                        if -1 == numFound {
                            foundString =
                                NSLocalizedString(
                                    "Unknown",
                                    comment: "the app does not know the number of works/editions/eBooks"
                                )
                        }
                        else {
                            foundString = String( numFound  )
                        }
                        footer.footerLabel.text =
                            "\(highWaterMark)" +
                            NSLocalizedString( " of ", comment: "X of Y" ) + foundString
                    }
                }
            }
        }
    }
    
    fileprivate func cachedData( _ cacheKey: String ) -> CacheData? {
        
        return OLQueryCoordinator.thumbnailCache.object( forKey: cacheKey as NSString )
    }
    
    fileprivate func cachedImage( _ localURL: URL ) -> UIImage? {
        
        guard localURL.isFileURL else {
            
            return nil
        }
        
        let cacheKey = localURL.lastPathComponent

        guard let cacheData = cachedData( cacheKey ) else {
            
            return nil
        }
        
        if let image = cacheData.image {
            
            return image
            
        } else {
            
            do {

                let data = try Data( contentsOf: localURL )
                
                if let image = UIImage( data: data ) {

                    OLQueryCoordinator.thumbnailCache.setObject( CacheData( image: image ), forKey: cacheKey as NSString )
                    
                    return image
                }
            }
            catch {}
        }
        
        return nil
    }
    
    fileprivate func displayThumbnailImage(
                    _ url: URL,
                    image: UIImage,
                    cell: OLCell
                ) {
        
        DispatchQueue.main.async {
            
            [weak cell] in
            
            if let cell = cell {
                
                _ = cell.displayImage( url, image: image )
            }
        }
    }
    
    fileprivate func enqueueImageFetch( _ url: URL, imageID: Int, imageType: String, cell: OLCell ) {
        
        guard libraryIsReachable( keepQuiet: true ) else {
            return
        }
        
        let pointSize = cell.imageSize()
        let imageGetOperation =
            ImageGetOperation( numberID: imageID, imageKeyName: "id", localURL: url, size: "M", type: imageType, displayPointSize: pointSize ) {
                
                [weak self, weak cell] in
                
                if let strongSelf = self, let cell = cell {
                    
                    if let image = strongSelf.cachedImage( url ) {
                        
                        strongSelf.displayThumbnailImage( url, image: image, cell: cell )
                    }
                }
        }
        
        imageGetOperation.userInitiated = true
        operationQueue.addOperation( imageGetOperation )
    }
    
    @discardableResult func displayThumbnail( _ object: OLManagedObject, cell: OLCell? ) -> Bool {
        
        guard object.hasImage else {
            return false
        }
        
        let url = object.localURL( "S" )
        let cacheKey = url.lastPathComponent
        
        // is there an entry in the cache?
        if let cacheData = cachedData( cacheKey ) {
            
            // is there an image on the entry?
            if let image = cacheData.image {
            
                if let cell = cell {
                    
                    _ = cell.displayImage( url, image: image )
                    return true
                }

            // otherwise, is there an image fetch in progress?
            } else if cacheData.fetchInProgress {

                return true
            }
        }

        OLQueryCoordinator.thumbnailCache.setObject( CacheData( image: nil ), forKey: cacheKey as NSString )

        // retrieve the thumbnail from openlibrary.org
        let imageID = object.firstImageID
        let imageType = object.imageType
        DispatchQueue( label: "preloadThumbnail", attributes: [] ).async {
            
            [weak self, weak cell] in

            if let strongSelf = self, let cell = cell {

                if let image = strongSelf.cachedImage( url ) {
                    
                    strongSelf.displayThumbnailImage(
                            url,
                            image: image,
                            cell: cell
                        )
                    
                } else {
                    
                    DispatchQueue.main.async {

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
        
        return true
    }
    
    // MARK: Reachability delegates

    fileprivate func reachable( _ reachability: Reachability ) {
        
        let currentDescription = reachability.description
        if currentDescription != OLQueryCoordinator.previousDescription {
            
            OLQueryCoordinator.previousDescription = currentDescription
        
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            DispatchQueue.main.async {
                let reachMessage = NSLocalizedString( "Reachable", comment: "the app can reach openlibrary.org" )
                let banner =
                    Banner(
                        title: NSLocalizedString( "Network Access", comment: "status title for network access" ),
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
    
    fileprivate func unreachable( _ reachability: Reachability ) {
        
        OLQueryCoordinator.previousDescription = reachability.description

        // this is called on a background thread, but UI updates must
        // be on the main thread, like this:
        DispatchQueue.main.async {
            let reachMessage = NSLocalizedString( "Not Reachable", comment: "the app cannot reach openlibrary.org" )
            let banner =
                Banner(
                    title: NSLocalizedString( "Network Access", comment: "status title for network access" ),
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
