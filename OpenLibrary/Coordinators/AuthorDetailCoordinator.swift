//
//  AuthorDetailCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/21/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

import BNRCoreDataStack
import PSOperations

let kAuthorDetailCache = "authorDetailSearch"

class AuthorDetailCoordinator: OLQueryCoordinator {
    
    typealias FetchedOLAuthorDetailController = FetchedResultsController< OLAuthorDetail >
    
    lazy var fetchedResultsController: FetchedOLAuthorDetailController = self.BuildFetchedResultsController()
    
    weak var authorDetailVC: OLAuthorDetailViewController?

    let authorKey: String
    var parentObjectID: NSManagedObjectID?
    weak var cachedAuthorDetail: OLAuthorDetail?
    var authorDetail: OLAuthorDetail {
        
        get {
            
            objc_sync_enter( self )
            defer {
                
                objc_sync_exit( self)
            }

            // manipulate the array
            guard nil == cachedAuthorDetail else {
                
                return cachedAuthorDetail!
            }
            
            guard let authorDetail = fetchedResultsController.fetchedObjects?.first else {
                
                fatalError( "author detail invalidated before fetch" )
            }
            
            cachedAuthorDetail = authorDetail
            
            return cachedAuthorDetail!
        }
        
        set {
            
            cachedAuthorDetail = newValue
        }
    }
    
    var deluxeData = [[DeluxeData]]()
    
    var authorDetailGetOperation: PSOperation?
    
    init(
        operationQueue: PSOperationQueue,
        coreDataStack: OLDataStack,
        authorKey: String,
        authorDetailVC: OLAuthorDetailViewController
        ) {
        
        self.authorKey = authorKey

        self.authorDetailVC = authorDetailVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: authorDetailVC )
    }
    
    
    func updateUI( _ authorDetail: OLAuthorDetail ) {
        
        if let authorDetailVC = authorDetailVC {
                
            DispatchQueue.main.async {
            
                authorDetailVC.updateUI( authorDetail )
                
                if authorDetail.hasImage {
                    
                    let mediumURL = authorDetail.localURL( "M" )
                    if !(authorDetailVC.displayImage( mediumURL )) {

                        let url = mediumURL
                        let imageGetOperation =
                            ImageGetOperation( numberID: authorDetail.firstImageID, imageKeyName: "ID", localURL: url, size: "M", type: authorDetail.imageType ) {
                                
                                    DispatchQueue.main.async {
                                        
                                        _ = authorDetailVC.displayImage( url )
                                    }
                                }
                        
                        imageGetOperation.userInitiated = true
                        self.operationQueue.addOperation( imageGetOperation )
                        
                        _ = authorDetailVC.displayImage( authorDetail.localURL( "S" ) )
                    }
                }
            }
        }
    }

    func updateUI() {
        
        do {
//            NSFetchedResultsController< OLAuthorDetail >.deleteCache( withName: kAuthorDetailCache )
            try fetchedResultsController.performFetch()
        }
        catch {
            
            print("Error in the author detail fetched results controller: \(error).")
        }
    }
    
    func newQuery( _ authorKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        guard libraryIsReachable() else {
            
            refreshComplete( refreshControl )
            return
        }
        
        if nil == authorDetailGetOperation {

            let getAuthorOperation =
                AuthorDetailGetOperation(
                    queryText: authorKey,
                    parentObjectID: parentObjectID,
                    coreDataStack: coreDataStack
                ) {
                    [weak self] in
                    
                    DispatchQueue.main.async {

                        if let strongSelf = self {
                            
//                            strongSelf.updateUI( strongSelf.authorDetail )

                            strongSelf.refreshComplete( refreshControl )
                        }
                    }
            }
            
            getAuthorOperation.userInitiated = true
            operationQueue.addOperation( getAuthorOperation )
        }
    }
    
    func refreshQuery( _ refreshControl: UIRefreshControl? ) {
        
        newQuery( authorKey, userInitiated: true, refreshControl: refreshControl )
    }
    
    // MARK: Utility
    func BuildFetchedResultsController() -> FetchedOLAuthorDetailController {
        
        let fetchRequest = OLAuthorDetail.buildFetchRequest()
        let key = authorKey
        
        let secondsPerDay = TimeInterval( 24 * 60 * 60 )
        let today = Date()
        let lastWeek = today.addingTimeInterval( -7 * secondsPerDay )
        
        fetchRequest.predicate = NSPredicate( format: "key==%@ && retrieval_date > %@", key, lastWeek as NSDate )
        
        fetchRequest.sortDescriptors =
            [
                NSSortDescriptor(key: "name", ascending: true)
            ]
        fetchRequest.fetchBatchSize = 100
        
        let frc =
            FetchedOLAuthorDetailController(
                fetchRequest: fetchRequest,
                managedObjectContext: self.coreDataStack.mainQueueContext,
                sectionNameKeyPath: nil,
                cacheName: nil // kAuthorDetailCache
        )
        
        frc.setDelegate( self )
        return frc
    }
    
    // MARK: install query coordinators
    
    func installAuthorWorksCoordinator( _ destVC: OLAuthorDetailWorksTableViewController ) {

        destVC.queryCoordinator =
            AuthorWorksCoordinator(
                    authorKey: authorKey,
                    authorWorksTableVC: destVC,
                    coreDataStack: coreDataStack,
                    operationQueue: operationQueue
                )
    }

    func installAuthorDeluxeDetailCoordinator( _ destVC: OLDeluxeDetailTableViewController ) {

        destVC.queryCoordinator =
            DeluxeDetailCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    heading: authorDetail.name,
                    deluxeData: authorDetail.deluxeData,
                    imageType: authorDetail.imageType,
                    deluxeDetailVC: destVC
                )
    }
    
    func installAuthorPictureCoordinator( _ destVC: OLPictureViewController ) {
        
        destVC.queryCoordinator =
            PictureViewCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    localURL: authorDetail.localURL( "L", index: 0 ),
                    imageID: authorDetail.firstImageID,
                    pictureType: authorDetail.imageType,
                    pictureVC: destVC
                )
    }
}

extension AuthorDetailCoordinator: FetchedResultsControllerDelegate {
    
    func fetchedResultsControllerDidPerformFetch( _ controller: FetchedOLAuthorDetailController ) {
        
        guard let authorDetail = controller.fetchedObjects?.first else {

            newQuery( self.authorKey, userInitiated: true, refreshControl: nil )
            return
        }
        
        self.authorDetail = authorDetail
        if authorDetail.isProvisional {
            
            newQuery( authorDetail.key, userInitiated: true, refreshControl: nil )

        } else {
            
            updateUI( authorDetail )
        }
    }
    
    func fetchedResultsControllerWillChangeContent( _ controller: FetchedOLAuthorDetailController ) {
        //        authorAuthorsTableVC?.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( _ controller: FetchedOLAuthorDetailController ) {
        
        guard let authorDetail = controller.fetchedObjects?.first else {
            
            newQuery( self.authorKey, userInitiated: true, refreshControl: nil )
            return
        }
        
        self.authorDetail = authorDetail
        updateUI( authorDetail )
    }
    
    func fetchedResultsController( _ controller: FetchedOLAuthorDetailController,
                                   didChangeObject change: FetchedResultsObjectChange< OLAuthorDetail > ) {
        
//        switch change {
//        case let .Insert( object, indexPath):
//            break
//            
//        case let .Delete(_, indexPath):
//            break
//            
//        case let .Move(_, fromIndexPath, toIndexPath):
//            break
//            
//        case let .Update( object, indexPath):
//            break
//        }
    }
    
    func fetchedResultsController(_ controller: FetchedOLAuthorDetailController,
                                  didChangeSection change: FetchedResultsSectionChange< OLAuthorDetail >) {
        
//        switch change {
//        case let .Insert(_, index):
//            break
//        case let .Delete(_, index):
//            break
//        }
    }
    
}

