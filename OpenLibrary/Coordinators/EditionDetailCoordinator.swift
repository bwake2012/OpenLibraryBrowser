//
//  EditionDetailCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/7/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

import BNRCoreDataStack

class EditionDetailCoordinator: OLQueryCoordinator {

    let editionDetail: OLEditionDetail
    weak var editionDetailVC: OLEditionDetailViewController?
    
    init(
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        searchInfo: OLEditionDetail,
        editionDetailVC: OLEditionDetailViewController
    ) {
        self.editionDetail = searchInfo
        self.editionDetailVC = editionDetailVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
    }
    
    func updateUI( editionDetail: OLEditionDetail ) {
        
        if let editionDetailVC = editionDetailVC {
            
            editionDetailVC.updateUI( editionDetail )
            
            if editionDetail.hasImage {
                
                let mediumURL = editionDetail.localURL( "M" )
                if !(editionDetailVC.displayImage( mediumURL )) {
                    
                    let url = mediumURL
                    let imageGetOperation =
                        ImageGetOperation( numberID: editionDetail.firstImageID, imageKeyName: "id", localURL: url, size: "M", type: "a" ) {
                            
                            dispatch_async( dispatch_get_main_queue() ) {
                                
                                editionDetailVC.displayImage( url )
                            }
                    }
                    
                    imageGetOperation.userInitiated = true
                    operationQueue.addOperation( imageGetOperation )
                    
                    editionDetailVC.displayImage( editionDetail.localURL( "S" ) )
                }
            }
        }
    }
    
    func updateUI() -> Void {
        
        updateUI( editionDetail )
    }
    
    func installCoverPictureViewCoordinator( destVC: OLPictureViewController ) {

        destVC.queryCoordinator =
            CoverPictureViewCoordinator(
                    operationQueue: self.operationQueue,
                    coreDataStack: self.coreDataStack,
                    managedObject: self.editionDetail,
                    pictureVC: destVC
                )
    }
}
