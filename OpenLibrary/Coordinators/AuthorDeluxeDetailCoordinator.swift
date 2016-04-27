//
//  AuthorDeluxeDetailCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/22/2016.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

import CoreData

import BNRCoreDataStack

let kAuthorDeluxeDetailCache = "authorDeluxeDetail"

class AuthorDeluxeDetailCoordinator: OLQueryCoordinator {
    
    weak var authorDetailVC: OLAuthorDeluxeDetailViewController?

    var searchInfo: OLAuthorSearchResult
        
    init(
            operationQueue: OperationQueue,
            coreDataStack: CoreDataStack,
            searchInfo: OLAuthorSearchResult,
            authorDetailVC: OLAuthorDeluxeDetailViewController
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
    
    // MARK: query coordinator installation
    
    func installAuthorPictureCoordinator( destVC: OLPictureViewController ) {
        
        destVC.queryCoordinator =
            AuthorPictureViewCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    searchInfo: searchInfo,
                    pictureVC: destVC
                )
    }
}
