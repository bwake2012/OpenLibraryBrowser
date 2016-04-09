//
//  AuthorPictureViewCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/6/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

import BNRCoreDataStack

class AuthorPictureViewCoordinator: OLQueryCoordinator, PictureViewCoordinatorProtocol {
    
    weak var pictureVC: OLPictureViewController?
    
    var searchInfo: OLAuthorSearchResult

    init(
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        searchInfo: OLAuthorSearchResult,
        pictureVC: OLPictureViewController
    ) {
    
        self.searchInfo = searchInfo
    
        self.pictureVC = pictureVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
    }
    
    func updateUI() {
        
        let localURL = searchInfo.localURL( "L" )
        
        if let pictureVC = pictureVC {
            if !(pictureVC.displayImage( localURL )) {
                
                if let authorDetail = searchInfo.toDetail {
                    
                    updateUI( authorDetail )
                    
                } else {
                
                    let getAuthorOperation =
                        AuthorDetailWithThumbGetOperation(
                            queryText: searchInfo.key, parentObjectID: searchInfo.objectID, size: "L",
                            coreDataStack: coreDataStack
                        ) {
                            [weak self] in
                            
                            if let strongSelf = self {

                                dispatch_async( dispatch_get_main_queue() ) {
                                    
                                    if let authorDetail = strongSelf.searchInfo.toDetail {
                                        
                                        strongSelf.updateUI( authorDetail )
                                    }
                                }
                            }
                    }
                    
                    getAuthorOperation.userInitiated = true
                    operationQueue.addOperation( getAuthorOperation )
                }
            }
        }
    }
    
    func updateUI( authorDetail: OLAuthorDetail ) {
        
        if authorDetail.hasImage {
                
            if let pictureVC = pictureVC {

                let localURL = authorDetail.localURL( "L" )
                
                let imageGetOperation =
                    ImageGetOperation( numberID: authorDetail.photos[0], imageKeyName: "ID", localURL: localURL, size: "L", type: "a" ) {
                        
                        dispatch_async( dispatch_get_main_queue() ) {
                            
                            pictureVC.displayImage( localURL )
                        }
                }
                
                imageGetOperation.userInitiated = true
                operationQueue.addOperation( imageGetOperation )
            }
        }
    }
    
    
    
}