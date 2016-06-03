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
    var authorDetailGetOperation: Operation?
    
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
    
    func retrieveAuthors ( editionDetail: OLEditionDetail ) {
        
        if nil == authorDetailGetOperation {

            let authorNames = editionDetail.author_names
            var authors = editionDetail.authors
            
            if authorNames.count < authors.count {
                
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
                                    
                                    strongSelf.updateUI( editionDetail )
                                    
                                    strongSelf.authorDetailGetOperation = nil
                                }
                            }
                    }
                    operationQueue.addOperation( authorDetailGetOperation! )
                }
            }
        }
    }
    
    func installCoverPictureViewCoordinator( destVC: OLPictureViewController ) {

        destVC.queryCoordinator =
            PictureViewCoordinator(
                    operationQueue: self.operationQueue,
                    coreDataStack: self.coreDataStack,
                    localURL: self.editionDetail.localURL( "L", index: 0 ),
                    imageID: self.editionDetail.firstImageID,
                    pictureType: "b",
                    pictureVC: destVC
                )
    }
}
