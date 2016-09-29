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
    
    weak var authorDetailVC: OLAuthorDetailViewController?

    var authorDetail: OLAuthorDetail?
    var authorKey: String
    var parentObjectID: NSManagedObjectID?
    
    var deluxeData = [[DeluxeData]]()
    
    var authorDetailGetOperation: Operation?
    
    init(
            operationQueue: OperationQueue,
            coreDataStack: CoreDataStack,
            searchInfo: OLAuthorSearchResult,
            authorDetailVC: OLAuthorDetailViewController
        ) {
        
        self.authorDetail = searchInfo.toDetail
        if searchInfo.key.hasPrefix( kAuthorsPrefix ) {
            self.authorKey = searchInfo.key
        } else {
            self.authorKey = kAuthorsPrefix + searchInfo.key
        }
        self.parentObjectID = searchInfo.objectID

        self.authorDetailVC = authorDetailVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: authorDetailVC )
    }
    
    init(
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        authorKey: String,
        authorDetailVC: OLAuthorDetailViewController
        ) {
        
        self.authorDetail = nil

        self.authorKey = authorKey
        if !self.authorKey.hasPrefix( kAuthorsPrefix ) {
            
            self.authorKey = kAuthorsPrefix + self.authorKey
        }
        
        self.authorDetailVC = authorDetailVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: authorDetailVC )

        assert( !authorKey.isEmpty )
    }
    
    init(
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        searchInfo: OLGeneralSearchResult,
        authorDetailVC: OLAuthorDetailViewController
        ) {
        
        self.authorDetail = nil
        
        self.authorKey = searchInfo.author_key[0]
        if !self.authorKey.hasPrefix( kAuthorsPrefix ) {
            
            self.authorKey = kAuthorsPrefix + self.authorKey
        }
        
        self.authorDetailVC = authorDetailVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: authorDetailVC )
        
        assert( !authorKey.isEmpty )
    }
    
    func updateUI( authorDetail: OLAuthorDetail ) {
        
        if let authorDetailVC = authorDetailVC {
                
            dispatch_async( dispatch_get_main_queue() ) {
            
                authorDetailVC.updateUI( authorDetail )
                
                if authorDetail.hasImage {
                    
                    let mediumURL = authorDetail.localURL( "M" )
                    if !(authorDetailVC.displayImage( mediumURL )) {

                        let url = mediumURL
                        let imageGetOperation =
                            ImageGetOperation( numberID: authorDetail.firstImageID, imageKeyName: "ID", localURL: url, size: "M", type: authorDetail.imageType ) {
                                
                                    dispatch_async( dispatch_get_main_queue() ) {
                                        
                                        authorDetailVC.displayImage( url )
                                    }
                                }
                        
                        imageGetOperation.userInitiated = true
                        self.operationQueue.addOperation( imageGetOperation )
                        
                        authorDetailVC.displayImage( authorDetail.localURL( "S" ) )
                    }
                }
            }
        }
    }

    func updateUI() {
        
        let detail: OLAuthorDetail? =
            OLAuthorDetail.findObject(
                    authorKey,
                    entityName: OLAuthorDetail.entityName,
                    moc: self.coreDataStack.mainQueueContext
                )
        
        if let detail = detail {

            authorDetail = detail
            updateUI( detail )
        }

        if nil == detail || nil != detail?.provisional_date {
            
            newQuery( authorKey, userInitiated: true, refreshControl: nil )
        }
    }
    
    func newQuery( authorKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
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
                    
                    if let strongSelf = self {
                        
                        dispatch_async( dispatch_get_main_queue() ) {

                            if nil == strongSelf.authorDetail {
                                
                                strongSelf.authorDetail =
                                    OLAuthorDetail.findObject(
                                            authorKey,
                                            entityName: OLAuthorDetail.entityName,
                                            moc: strongSelf.coreDataStack.mainQueueContext
                                        )
                            }
                            if let detail = strongSelf.authorDetail {
                                
                                strongSelf.updateUI( detail )

                                strongSelf.refreshComplete( refreshControl )
                            }
                        }
                    }
            }
            
            getAuthorOperation.userInitiated = true
            operationQueue.addOperation( getAuthorOperation )
        }
    }
    
    func refreshQuery( refreshControl: UIRefreshControl? ) {
        
        newQuery( self.authorKey, userInitiated: true, refreshControl: refreshControl )
    }
    
//    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLAuthorDetail? {
//        
//        guard let sections = fetchedResultsController.sections else {
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
//
    
    // MARK: install query coordinators
    
    func installAuthorWorksCoordinator( destVC: OLAuthorDetailWorksTableViewController ) {

        destVC.queryCoordinator =
            AuthorWorksCoordinator(
                    authorKey: authorKey,
                    authorWorksTableVC: destVC,
                    coreDataStack: coreDataStack,
                    operationQueue: operationQueue
                )
    }

    func installAuthorEditionsCoordinator( destVC: OLAuthorDetailEditionsTableViewController ) {
        
        destVC.queryCoordinator =
            AuthorEditionsCoordinator(
                    authorKey: authorKey,
                    tableVC: destVC,
                    coreDataStack: coreDataStack,
                    operationQueue: operationQueue
                )
    }
    
    func installAuthorDeluxeDetailCoordinator( destVC: OLDeluxeDetailTableViewController ) {
        
        if let authorDetail = authorDetail {
            
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
    }
    
    func installAuthorPictureCoordinator( destVC: OLPictureViewController ) {
        
        if let authorDetail = authorDetail {
            
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
}
