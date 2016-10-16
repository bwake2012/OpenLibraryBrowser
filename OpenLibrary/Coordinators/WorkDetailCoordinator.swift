//
//  WorkDetailCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/21/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

import BNRCoreDataStack
import PSOperations

private let kWorkDetailCache = "workDetailSearch"

class WorkDetailCoordinator: OLQueryCoordinator {
    
    typealias FetchedOLWorkDetailController = FetchedResultsController< OLWorkDetail >
    
    lazy var fetchedResultsController: FetchedOLWorkDetailController = self.BuildFetchedResultsController()
    
    weak var workDetailVC: OLWorkDetailViewController?

    var workKey: String
    
    weak var cachedWorkDetail: OLWorkDetail?
    var workDetail: OLWorkDetail {
        
        get {
            
            objc_sync_enter( self )
            defer {
                
                objc_sync_exit( self)
            }

            guard nil == cachedWorkDetail else {
                
                return cachedWorkDetail!
            }
            
            guard let workDetail = fetchedResultsController.fetchedObjects?.first else {
                
                fatalError( "work detail invalidated before fetch" )
            }
            
            cachedWorkDetail = workDetail
            
            return cachedWorkDetail!
        }
        
        set {
            
            cachedWorkDetail = newValue
        }
    }
    var editionKeys: [String] = []
    
    var workDetailGetOperation: Operation?
    var authorDetailGetOperation: Operation?
    var ebookItemGetOperation: Operation?
    
    init(
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        workDetail: OLWorkDetail,
        editionKeys: [String],
        workDetailVC: OLWorkDetailViewController
        ) {
        
        assert( !workDetail.key.isEmpty )
        
        self.workKey = workDetail.key
        self.cachedWorkDetail = workDetail
        self.editionKeys = editionKeys
        self.workDetailVC = workDetailVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: workDetailVC )
    }
    
    func updateUI( workDetail: OLWorkDetail ) {
        
        assert( NSThread.isMainThread() )
        assert( !workDetail.key.isEmpty )

        if let workDetailVC = workDetailVC {
            
            retrieveAuthors( workDetail )
            retrieveEBookItems( workDetail )
            
            workDetailVC.updateUI( workDetail )
            
            if workDetail.hasImage {
                
                let localURL = workDetail.localURL( "M" )
                if !( workDetailVC.displayImage( localURL ) ) {

                    let url = localURL
                    let imageGetOperation =
                        ImageGetOperation( numberID: workDetail.covers[0], imageKeyName: "id", localURL: url, size: "M", type: "a" ) {
                            
                            [weak self] in
                            
                            dispatch_async( dispatch_get_main_queue() ) {
                                    
                                if nil != self {

                                    workDetailVC.displayImage( url )
                                }
                            }
                    }
                    
                    imageGetOperation.userInitiated = true
                    operationQueue.addOperation( imageGetOperation )
                    
                    workDetailVC.displayImage( workDetail.localURL( "S" ) )
                }
            }
        }
    }

    func updateUI() {
        
        do {
            NSFetchedResultsController.deleteCacheWithName( kWorkDetailCache )
            try fetchedResultsController.performFetch()
        }
        catch {
            
            print("Error in the work detail fetched results controller: \(error).")
        }
    }
    
    func newQuery( workKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        if nil == workDetailGetOperation {
            workDetailGetOperation =
                WorkDetailGetOperation(
                    queryText: workKey,
                    coreDataStack: coreDataStack,
                    resultHandler: nil
                ) {
                    [weak self] in
                    
                    dispatch_async( dispatch_get_main_queue() ) {
                    
                        if let strongSelf = self {
                            
//                            strongSelf.updateUI( strongSelf.workDetail )
                            
                            strongSelf.refreshComplete( refreshControl )
                        }
                    }
            }
            
            workDetailGetOperation!.userInitiated = true
            operationQueue.addOperation( workDetailGetOperation! )
        }
    }
    
    func retrieveAuthors ( workDetail: OLWorkDetail ) {
        
        if workDetail.author_names.count < workDetail.authors.count {

            newAuthorQueries( workDetail )
        }
    }
    
    func newAuthorQueries( workDetail: OLWorkDetail ) {
        
        if nil == authorDetailGetOperation {
            
            var authors = workDetail.authors
            
            let firstOLID = authors.removeFirst()
            
            for olid in authors {
                
                if !olid.isEmpty && nil == workDetail.cachedAuthor( olid ) {
                    
                    let operation =
                        AuthorDetailGetOperation(
                            queryText: olid,
                            parentObjectID: nil,
                            coreDataStack: coreDataStack
                        ) {}
                    operationQueue.addOperation( operation )
                }
            }
            
            if !firstOLID.isEmpty {
                
                authorDetailGetOperation =
                    AuthorDetailGetOperation(
                        queryText: firstOLID,
                        parentObjectID: nil,
                        coreDataStack: coreDataStack
                    ) {
                        
                        [weak self] in
                        
                        dispatch_async( dispatch_get_main_queue() ) {
                                
                            if let strongSelf = self {
                                
//                                strongSelf.updateUI( strongSelfworkDetail )
                                
                                strongSelf.authorDetailGetOperation = nil
                            }
                        }
                }
                operationQueue.addOperation( authorDetailGetOperation! )
            }
        }
    }
    
    func retrieveEBookItems ( workDetail: OLWorkDetail ) {
        
        if workDetail.mayHaveFullText && workDetail.ebook_items.isEmpty  {
            
            newEbookItemQuery( workDetail )
        }
    }
    
    func newEbookItemQuery( workDetail: OLWorkDetail ) {
    
        guard libraryIsReachable() else {
            
            return
        }
        
        if nil == ebookItemGetOperation {
            
            ebookItemGetOperation =
                WorkEditionEbooksGetOperation(
                    workKey: workDetail.key,
                    coreDataStack: coreDataStack
                ) {
                    
                    [weak self] in
                    
                    dispatch_async( dispatch_get_main_queue() ) {
                            
                        if let strongSelf = self {
                            
                            if workDetail.ebook_items.isEmpty {
                                
                                workDetail.has_fulltext = 0
                            }
                            
                            strongSelf.ebookItemGetOperation = nil
                        }
                    }
            }
            operationQueue.addOperation( ebookItemGetOperation! )
        }
    }
    
    func refreshQuery( refreshControl: UIRefreshControl? ) {
        
        newQuery( workKey, userInitiated: true, refreshControl: refreshControl )

    }
    
    // MARK: Utility
    func BuildFetchedResultsController() -> FetchedOLWorkDetailController {
        
        let fetchRequest = NSFetchRequest( entityName: OLWorkDetail.entityName )
        let key = workKey
        
        let secondsPerDay = NSTimeInterval( 24 * 60 * 60 )
        let today = NSDate()
        let lastWeek = today.dateByAddingTimeInterval( -7 * secondsPerDay )
        
        fetchRequest.predicate = NSPredicate( format: "key==%@ && retrieval_date > %@", "\(key)", lastWeek )
        
        fetchRequest.sortDescriptors =
            [
                //                NSSortDescriptor(key: "coversFound", ascending: false),
                NSSortDescriptor(key: "index", ascending: true)
            ]
        fetchRequest.fetchBatchSize = 100
        
        let frc =
            FetchedOLWorkDetailController(
                    fetchRequest: fetchRequest,
                    managedObjectContext: self.coreDataStack.mainQueueContext,
                    sectionNameKeyPath: nil,
                    cacheName: kWorkDetailCache
                )
        
        frc.setDelegate( self )
        return frc
    }
    
    // MARK: install query coordinators
    
    func installWorkDetailEditionsQueryCoordinator( destVC: OLWorkDetailEditionsTableViewController ) {
        
        destVC.queryCoordinator =
            WorkEditionsCoordinator(
                workDetail: workDetail,
                tableVC: destVC,
                coreDataStack: self.coreDataStack,
                operationQueue: self.operationQueue
        )
     }
    
    func installEBookEditionsCoordinator( destVC: OLEBookEditionsTableViewController ) {
        
        assert( !editionKeys.isEmpty )
        
        destVC.queryCoordinator =
            EBookEditionsCoordinator(
                operationQueue: operationQueue,
                coreDataStack: coreDataStack,
                workDetail: workDetail,
                editionKeys: editionKeys,
                tableVC: destVC
        )
    }

    func installWorkDeluxeDetailCoordinator( destVC: OLDeluxeDetailTableViewController ) {
        
        destVC.queryCoordinator =
            DeluxeDetailCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    heading: workDetail.title,
                    deluxeData: workDetail.deluxeData,
                    imageType: workDetail.imageType,
                    deluxeDetailVC: destVC
                )
    }
    
    func installCoverPictureViewCoordinator( destVC: OLPictureViewController ) {
    
        destVC.queryCoordinator =
            PictureViewCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    localURL: workDetail.localURL( "L", index: 0 ),
                    imageID: workDetail.firstImageID,
                    pictureType: workDetail.imageType,
                    pictureVC: destVC
                )

    }
    
    func installAuthorDetailCoordinator( destVC: OLAuthorDetailViewController ) {
        
        guard !workDetail.author_key.isEmpty else {
            
            fatalError( "work has no author keys!" )
        }
        
        guard !workDetail.author_key.isEmpty else {
            
            fatalError( "work has no authors!" )
        }
        
        destVC.queryCoordinator =
            AuthorDetailCoordinator(
                operationQueue: operationQueue,
                coreDataStack: coreDataStack,
                authorKey: workDetail.author_key,
                authorDetailVC: destVC
            )
    }
    
}

extension WorkDetailCoordinator: FetchedResultsControllerDelegate {
    
    func fetchedResultsControllerDidPerformFetch( controller: FetchedOLWorkDetailController ) {
        
        guard let workDetail = controller.fetchedObjects?.first else {
            
            newQuery( workKey, userInitiated: true, refreshControl: nil )
            return
        }
        
        self.workDetail = workDetail

        if workDetail.isProvisional {
            
            newQuery( workDetail.key, userInitiated: true, refreshControl: nil )
        }

        updateUI( workDetail )
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedOLWorkDetailController ) {
        //        authorWorksTableVC?.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedOLWorkDetailController ) {
        
        guard let workDetail = controller.fetchedObjects?.first else {
            
            newQuery( self.workKey, userInitiated: true, refreshControl: nil )
            return
        }
        
        self.workDetail = workDetail
        updateUI( workDetail )
    }
    
    func fetchedResultsController( controller: FetchedOLWorkDetailController,
                                   didChangeObject change: FetchedResultsObjectChange< OLWorkDetail > ) {
        
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
    
    func fetchedResultsController(controller: FetchedOLWorkDetailController,
                                  didChangeSection change: FetchedResultsSectionChange< OLWorkDetail >) {
        
//        switch change {
//        case let .Insert(_, index):
//            break
//        case let .Delete(_, index):
//            break
//        }
    }
    
}
