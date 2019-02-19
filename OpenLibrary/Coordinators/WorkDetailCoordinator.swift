//
//  WorkDetailCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/21/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

//import BNRCoreDataStack
import PSOperations

private let kWorkDetailCache = "workDetailSearch"

class WorkDetailCoordinator: OLQueryCoordinator {
    
    typealias FetchedOLWorkDetailController = NSFetchedResultsController< OLWorkDetail >
    
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
    
    var workDetailGetOperation: PSOperation?
    var authorDetailGetOperation: PSOperation?
    var ebookItemGetOperation: PSOperation?
    
    init(
        operationQueue: PSOperationQueue,
        dataStack: OLDataStack,
        workDetail: OLWorkDetail,
        editionKeys: [String],
        workDetailVC: OLWorkDetailViewController
        ) {
        
        assert( !workDetail.key.isEmpty )
        
        self.workKey = workDetail.key
        self.cachedWorkDetail = workDetail
        self.editionKeys = editionKeys
        self.workDetailVC = workDetailVC
        
        super.init( operationQueue: operationQueue, dataStack: dataStack, viewController: workDetailVC )
    }
    
    func updateUI( _ workDetail: OLWorkDetail ) {
        
        assert( Thread.isMainThread )
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
                            
                            DispatchQueue.main.async {
                                    
                                if nil != self {

                                    _ = workDetailVC.displayImage( url )
                                }
                            }
                    }
                    
                    imageGetOperation.userInitiated = true
                    operationQueue.addOperation( imageGetOperation )
                    
                    _ = workDetailVC.displayImage( workDetail.localURL( "S" ) )
                }
            }
        }
    }

    func updateUI() {
        
        do {
//            NSFetchedResultsController< OLWorkDetail >.deleteCache( withName: kWorkDetailCache )
            try fetchedResultsController.performFetch()
            
            controllerDidPerformFetch( fetchedResultsController )
        }
        catch {
            
            print("Error in the work detail fetched results controller: \(error).")
        }
    }
    
    func newQuery( _ workKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        if nil == workDetailGetOperation {

            let workDetailID = cachedWorkDetail?.objectID
            workDetailGetOperation =
                WorkDetailGetOperation(
                    queryText: workKey,
                    currentObjectID: workDetailID,
                    dataStack: dataStack,
                    resultHandler: nil
                ) {
                    [weak self] in
                    
                    DispatchQueue.main.async {
                    
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
    
    func retrieveAuthors ( _ workDetail: OLWorkDetail ) {
        
        if workDetail.author_names.count < workDetail.authors.count {

            newAuthorQueries( workDetail )
        }
    }
    
    func newAuthorQueries( _ workDetail: OLWorkDetail ) {
        
        if nil == authorDetailGetOperation {
            
            var authors = workDetail.authors
            
            let firstOLID = authors.removeFirst()
            
            for olid in authors {
                
                if !olid.isEmpty && nil == workDetail.cachedAuthor( olid ) {
                    
                    let operation =
                        AuthorDetailGetOperation(
                            queryText: olid,
                            parentObjectID: nil,
                            dataStack: dataStack
                        ) {}
                    operationQueue.addOperation( operation )
                }
            }
            
            if !firstOLID.isEmpty {
                
                authorDetailGetOperation =
                    AuthorDetailGetOperation(
                        queryText: firstOLID,
                        parentObjectID: nil,
                        dataStack: dataStack
                    ) {
                        
                        [weak self] in
                        
                        DispatchQueue.main.async {
                                
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
    
    func retrieveEBookItems ( _ workDetail: OLWorkDetail ) {
        
        if workDetail.mayHaveFullText && workDetail.ebook_items.isEmpty  {
            
            newEbookItemQuery()
        }
    }
    
    func newEbookItemQuery() {
    
        guard libraryIsReachable() else {
            
            return
        }
        
        if nil == ebookItemGetOperation {
            
            ebookItemGetOperation =
                WorkEditionEbooksGetOperation(
                    workKey: self.workDetail.key,
                    dataStack: dataStack
                ) {
                    
                    [weak self] in
                    
                    DispatchQueue.main.async {
                            
                        if let strongSelf = self {
                            
                            if strongSelf.workDetail.ebook_items.isEmpty {
                                
                                strongSelf.workDetail.has_fulltext = 0
                            }
                            
                            strongSelf.ebookItemGetOperation = nil
                        }
                    }
            }
            operationQueue.addOperation( ebookItemGetOperation! )
        }
    }
    
    func refreshQuery( _ refreshControl: UIRefreshControl? ) {
        
        newQuery( workKey, userInitiated: true, refreshControl: refreshControl )

    }
    
    // MARK: install query coordinators
    
    func installWorkDetailEditionsQueryCoordinator( _ destVC: OLWorkDetailEditionsTableViewController ) {
        
        destVC.queryCoordinator =
            WorkEditionsCoordinator(
                workDetail: workDetail,
                tableVC: destVC,
                dataStack: self.dataStack,
                operationQueue: self.operationQueue
        )
     }
    
    func installEBookEditionsCoordinator( _ destVC: OLEBookEditionsTableViewController ) {
        
        assert( !editionKeys.isEmpty )
        
        destVC.queryCoordinator =
            EBookEditionsCoordinator(
                operationQueue: operationQueue,
                dataStack: dataStack,
                workDetail: workDetail,
                editionKeys: editionKeys,
                tableVC: destVC
        )
    }

    func installWorkDeluxeDetailCoordinator( _ destVC: OLDeluxeDetailTableViewController ) {
        
        destVC.queryCoordinator =
            DeluxeDetailCoordinator(
                    operationQueue: operationQueue,
                    dataStack: dataStack,
                    heading: workDetail.title,
                    deluxeData: workDetail.deluxeData,
                    imageType: workDetail.imageType,
                    deluxeDetailVC: destVC
                )
    }
    
    func installCoverPictureViewCoordinator( _ destVC: OLPictureViewController ) {
    
        destVC.queryCoordinator =
            PictureViewCoordinator(
                    operationQueue: operationQueue,
                    dataStack: dataStack,
                    localURL: workDetail.localURL( "L", index: 0 ),
                    imageID: workDetail.firstImageID,
                    pictureType: workDetail.imageType,
                    pictureVC: destVC
                )

    }
    
    func installAuthorDetailCoordinator( _ destVC: OLAuthorDetailViewController ) {
        
        guard !workDetail.author_key.isEmpty else {
            
            fatalError( "work has no author keys!" )
        }
        
        guard !workDetail.author_key.isEmpty else {
            
            fatalError( "work has no authors!" )
        }
        
        destVC.queryCoordinator =
            AuthorDetailCoordinator(
                operationQueue: operationQueue,
                dataStack: dataStack,
                authorKey: workDetail.author_key,
                authorDetailVC: destVC
            )
    }
    
}

extension WorkDetailCoordinator: NSFetchedResultsControllerDelegate {
    
    func BuildFetchedResultsController() -> FetchedOLWorkDetailController {
        
        let fetchRequest = OLWorkDetail.buildFetchRequest()
        let key = workKey
        
        let secondsPerDay = TimeInterval( 24 * 60 * 60 )
        let today = Date()
        let lastWeek = today.addingTimeInterval( -7 * secondsPerDay )
        
        fetchRequest.predicate = NSPredicate( format: "key==%@ && retrieval_date > %@", key, lastWeek as NSDate )
        
        fetchRequest.sortDescriptors =
            [
                //                NSSortDescriptor(key: "coversFound", ascending: false),
                NSSortDescriptor(key: "index", ascending: true)
        ]
        fetchRequest.fetchBatchSize = 100
        
        let frc =
            FetchedOLWorkDetailController(
                fetchRequest: fetchRequest,
                managedObjectContext: self.dataStack.mainQueueContext,
                sectionNameKeyPath: nil,
                cacheName: nil // kWorkDetailCache
        )
        
        frc.delegate = self
        return frc
    }
    
    func controllerDidPerformFetch( _ controller: FetchedOLWorkDetailController ) {
        
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
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        guard let workDetail = controller.fetchedObjects?.first as? OLWorkDetail else {
            
            newQuery( self.workKey, userInitiated: true, refreshControl: nil )
            return
        }
        
        self.workDetail = workDetail
        updateUI( workDetail )
    }
    
    
}
