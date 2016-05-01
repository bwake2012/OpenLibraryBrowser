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
    
    var authorDetail: OLAuthorDetail

    init(
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        authorDetail: OLAuthorDetail,
        pictureVC: OLPictureViewController
    ) {
    
        self.authorDetail = authorDetail
    
        self.pictureVC = pictureVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
    }
    
    func updateUI() {
        
        let localURL = authorDetail.localURL( "L" )
        
        if let pictureVC = pictureVC {
            if !(pictureVC.displayImage( localURL )) {
 
                
                let getImageOperation =
                    ImageGetOperation(
                    numberID: authorDetail.firstImageID, imageKeyName: "id", localURL: localURL, size: "L", type: "a"
                    ) {
                        [weak self] in
                        
                        if let strongSelf = self {

                            dispatch_async( dispatch_get_main_queue() ) {
                                
                                strongSelf.updateUI( strongSelf.authorDetail )
                            }
                        }
                }
                
                getImageOperation.userInitiated = true
                operationQueue.addOperation( getImageOperation )
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