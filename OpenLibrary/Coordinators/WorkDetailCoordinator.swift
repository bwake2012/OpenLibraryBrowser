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
    
    weak var workDetailVC: OLWorkDetailViewController?

    var workDetail: OLWorkDetail?
    var workKey: String
    var editionKeys: [String] = []
    
    var workDetailGetOperation: Operation?
    var authorDetailGetOperation: Operation?
    var ebookItemGetOperation: Operation?
    
    init(
            operationQueue: OperationQueue,
            coreDataStack: CoreDataStack,
            searchInfo: OLWorkDetail,
            workDetailVC: OLWorkDetailViewController
        ) {
        
        self.workDetail = searchInfo
        self.workKey = searchInfo.key
        self.editionKeys = []
        self.workDetailVC = workDetailVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: workDetailVC )
    }
    
    init(
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        workKey: String,
        editionKeys: [String],
        workDetailVC: OLWorkDetailViewController
        ) {
        
        assert( !workKey.isEmpty )
        
        self.workDetail = nil
        self.workKey = workKey
        self.editionKeys = editionKeys
        self.workDetailVC = workDetailVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: workDetailVC )
    }
    
    func updateUI( workDetail: OLWorkDetail ) {
        
        assert( NSThread.isMainThread() )

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
                            
                            if nil != self {

                                dispatch_async( dispatch_get_main_queue() ) {
                                    
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
    
    func getSearchInfo( objectID: NSManagedObjectID ) {
        
        dispatch_async( dispatch_get_main_queue() ) {

            if let workDetail = self.coreDataStack.mainQueueContext.objectWithID( objectID ) as? OLWorkDetail {
                
                self.workDetail = workDetail
            }
        }
    }
    
    func updateUI() {
        
        let detail: OLWorkDetail? =
            OLWorkDetail.findObject(
                    workKey,
                    entityName: OLWorkDetail.entityName,
                    moc: self.coreDataStack.mainQueueContext
                )
        
        if let detail = detail {
            
            workDetail = detail
            updateUI( detail )
        }
        
        if nil == detail || nil != detail?.provisional_date {
            
            newQuery( workKey, userInitiated: true, refreshControl: nil )
        }
    }
    
    func newQuery( workKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        if nil == workDetailGetOperation {
            workDetailGetOperation =
                WorkDetailGetOperation(
                    queryText: workKey,
                    coreDataStack: coreDataStack,
                    resultHandler: getSearchInfo
                ) {
                    [weak self] in
                    
                    if let strongSelf = self {
                        dispatch_async( dispatch_get_main_queue() ) {
                            
                            if nil == strongSelf.workDetail {

                                strongSelf.workDetail =
                                    OLWorkDetail.findObject(
                                        workKey,
                                        entityName: OLWorkDetail.entityName,
                                        moc: strongSelf.coreDataStack.mainQueueContext
                                )
                            }
                            if let detail = strongSelf.workDetail {
                                
                                strongSelf.updateUI( detail )
                                
                                strongSelf.refreshComplete( refreshControl )
                            }
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
                
                if !olid.isEmpty {
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
                        
                        if let strongSelf = self {
                            
                            dispatch_async( dispatch_get_main_queue() ) {
                                
                                strongSelf.updateUI( workDetail )
                                
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
                    
                    if let strongSelf = self {
                        
                        dispatch_async( dispatch_get_main_queue() ) {
                            
                            if workDetail.ebook_items.isEmpty {
                                
                                workDetail.has_fulltext = 0
                            }
                            strongSelf.updateUI( workDetail )
                            
                            strongSelf.ebookItemGetOperation = nil
                        }
                    }
            }
            operationQueue.addOperation( ebookItemGetOperation! )
        }
    }
    
//    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLWorkDetail? {
//        
//        guard let sections = fetchedWorkDetailController.sections else {
//            assertionFailure("Sections missing")
//            return nil
//        }
//        
//        let section = sections[indexPath.section]
//        if indexPath.row >= section.objects.count {
//            return nil
//        } else {
//            return section.objects[indexPath.row]
//        }
//    }
    
    func refreshQuery( refreshControl: UIRefreshControl? ) {
        
        newQuery( self.workKey, userInitiated: true, refreshControl: refreshControl )
        if let workDetail = workDetail {
            
            workDetail.resetAuthors()
            newAuthorQueries( workDetail )
            
            workDetail.resetFulltext()
            newEbookItemQuery( workDetail )
        }
    }
    
    // MARK: Utility
    
    func findAuthorDetailInStack( navigationController: UINavigationController ) -> OLAuthorDetailViewController? {
        
        var index = navigationController.viewControllers.count - 1
        repeat {
            
            let vc = navigationController.viewControllers[index]
            
            if let authorDetailVC = vc as? OLAuthorDetailViewController {
                
                if authorDetailVC.queryCoordinator?.authorKey == workDetail?.author_key {
                    
                    return authorDetailVC
                }
            }
            
            index -= 1
            
        } while index > 0
        
        return nil
    }

    // MARK: install query coordinators
    
    func installWorkDetailEditionsQueryCoordinator( destVC: OLWorkDetailEditionsTableViewController ) {
        
        let workKey = self.workKey
        assert( !workKey.isEmpty )
        
        destVC.queryCoordinator =
            WorkEditionsCoordinator(
                workKey: workKey,
                withCoversOnly: true,
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
                workKey: workKey,
                editionKeys: editionKeys,
                tableVC: destVC
        )
    }

    func installWorkDeluxeDetailCoordinator( destVC: OLDeluxeDetailTableViewController ) {
        
        guard let workDetail = workDetail else {
            fatalError( "Work Detail object not retrieved.")
        }
        
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
    
        guard let workDetail = workDetail else {
            fatalError( "Work Detail object not retrieved.")
        }
        
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
        
        guard let workDetail = workDetail else {
            fatalError( "Work Detail object not retrieved.")
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
