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
            
            authorDetailVC.UpdateUI( authorDetail )
            
            if authorDetail.photos.count > 0 {
                
                let mediumURL = authorDetail.localURL( "M" )
                if !(authorDetailVC.displayImage( mediumURL )) {

                    let url = mediumURL
                    let imageGetOperation =
                        ImageGetOperation( numberID: authorDetail.photos[0], imageKeyName: "ID", localURL: url, size: "M", type: "a" ) {
                            
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
                    queryText: searchInfo.key, parentObjectID: searchInfo.objectID,
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
    
    func setAuthorWorksCoordinator( destVC: OLAuthorDetailWorksTableViewController, searchInfo: OLAuthorSearchResult ) {

        destVC.queryCoordinator =
            AuthorWorksCoordinator( searchInfo: searchInfo, authorWorksTableVC: destVC, coreDataStack: coreDataStack, operationQueue: operationQueue )
    }
    
    func setAuthorEditionsCoordinator( destVC: OLAuthorDetailEditionsTableViewController, searchInfo: OLAuthorSearchResult ) {
        
        destVC.queryCoordinator =
            AuthorEditionsCoordinator( searchInfo: searchInfo, withCoversOnly: false, tableVC: destVC, coreDataStack: coreDataStack, operationQueue: operationQueue )
    }
    
    func setAuthorPictureCoordinator( destVC: OLPictureViewController, searchInfo: OLAuthorSearchResult ) {
        
        destVC.queryCoordinator =
            AuthorPictureViewCoordinator(
                    operationQueue: self.operationQueue,
                    coreDataStack: self.coreDataStack,
                    searchInfo: searchInfo,
                    pictureVC: destVC
                )

    }
}
