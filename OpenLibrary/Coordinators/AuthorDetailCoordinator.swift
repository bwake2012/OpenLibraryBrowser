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

let kAuthorDetailCache = "authorDetailSearch"

class AuthorDetailCoordinator: OLQueryCoordinator {
    
    weak var authorDetailVC: OLAuthorDetailViewController?

    var searchInfo: OLAuthorSearchResult
    
    var deluxeData = [[DeluxeData]]()
    
    init(
            operationQueue: OperationQueue,
            coreDataStack: CoreDataStack,
            searchInfo: OLAuthorSearchResult,
            authorDetailVC: OLAuthorDetailViewController
        ) {
        
        self.searchInfo = searchInfo
        self.authorDetailVC = authorDetailVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
    }
    
    
    func updateUI( authorDetail: OLAuthorDetail ) {
        
        if let authorDetailVC = authorDetailVC {
            
            authorDetailVC.updateUI( authorDetail )
            
            if authorDetail.hasImage {
                
                let mediumURL = authorDetail.localURL( "M" )
                if !(authorDetailVC.displayImage( mediumURL )) {

                    let url = mediumURL
                    let imageGetOperation =
                        ImageGetOperation( numberID: authorDetail.firstImageID, imageKeyName: "ID", localURL: url, size: "M", type: "a" ) {
                            
                                dispatch_async( dispatch_get_main_queue() ) {
                                    
                                    authorDetailVC.displayImage( url )
                                }
                            }
                    
                    imageGetOperation.userInitiated = true
                    operationQueue.addOperation( imageGetOperation )
                    
                    authorDetailVC.displayImage( authorDetail.localURL( "S" ) )
                }
            }
        }
    }

    func updateUI() -> Void {
        
        if let detail = searchInfo.toDetail {
            updateUI( detail )
        } else {
            
            let getAuthorOperation =
                AuthorDetailGetOperation(
                    queryText: searchInfo.key,
                    parentObjectID: searchInfo.objectID,
                    coreDataStack: coreDataStack
                ) {
                    [weak self] in
                    
                    if let strongSelf = self {
                        dispatch_async( dispatch_get_main_queue() ) {
                            
                            if let detail = strongSelf.searchInfo.toDetail {
                                
                                strongSelf.updateUI( detail )
                            }
                        }
                    }
            }
            
            getAuthorOperation.userInitiated = true
            operationQueue.addOperation( getAuthorOperation )
        }
    }
        
    // MARK: install query coordinators
    
    func installAuthorWorksCoordinator( destVC: OLAuthorDetailWorksTableViewController ) {

        destVC.queryCoordinator =
            AuthorWorksCoordinator(
                    searchInfo: searchInfo,
                    authorWorksTableVC: destVC,
                    coreDataStack: coreDataStack,
                    operationQueue: operationQueue
                )
    }

    func installAuthorEditionsCoordinator( destVC: OLAuthorDetailEditionsTableViewController ) {
        
        destVC.queryCoordinator =
            AuthorEditionsCoordinator(
                    searchInfo: searchInfo,
                    withCoversOnly: false,
                    tableVC: destVC,
                    coreDataStack: coreDataStack,
                    operationQueue: operationQueue
                )
    }
    
    func installAuthorDeluxeDetailCoordinator( destVC: OLAuthorDeluxeDetailTableViewController ) {
        
        destVC.queryCoordinator =
            AuthorDeluxeDetailCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    authorDetail: searchInfo.toDetail!,
                    authorDeluxeDetailVC: destVC
                )
    }
    
    func installAuthorPictureCoordinator( destVC: OLPictureViewController ) {
        
        destVC.queryCoordinator =
            AuthorPictureViewCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    authorDetail: searchInfo.toDetail!,
                    pictureVC: destVC
                )
    }
}
