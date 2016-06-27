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
    var ebookItemGetOperation: Operation?
    
    init(
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        searchInfo: OLEditionDetail,
        editionDetailVC: OLEditionDetailViewController
    ) {
        self.editionDetail = searchInfo
        self.editionDetailVC = editionDetailVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: editionDetailVC )
    }
    
    func updateUI( editionDetail: OLEditionDetail ) {
        
        if let editionDetailVC = editionDetailVC {
            
            retrieveAuthors( editionDetail )
            retrieveEBookItems( editionDetail )
            
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
        
        if editionDetail.author_names.count < editionDetail.authors.count {
            
            newAuthorQueries( editionDetail )
        }
    }
    
    func newAuthorQueries( editionDetail: OLEditionDetail ) {
        
        if nil == authorDetailGetOperation {
            
            var authors = editionDetail.authors
            
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
    
    func retrieveEBookItems ( editionDetail: OLEditionDetail ) {
        
        if editionDetail.mayHaveFullText && editionDetail.ebook_items.isEmpty  {
            
            newEbookItemQuery( editionDetail )
        }
    }
    
    func newEbookItemQuery( editionDetail: OLEditionDetail ) {
        
        if nil == ebookItemGetOperation {
            
            ebookItemGetOperation =
                IAEBookItemGetOperation(
                    editionKey: editionDetail.key,
                    coreDataStack: coreDataStack
                ) {
                    
                    [weak self] in
                    
                    if let strongSelf = self {
                        
                        dispatch_async( dispatch_get_main_queue() ) {
                            
                            if editionDetail.ebook_items.isEmpty {
                                
                                editionDetail.has_fulltext = 0
                            }
                            strongSelf.updateUI( editionDetail )
                            
                            strongSelf.ebookItemGetOperation = nil
                        }
                    }
            }
            operationQueue.addOperation( ebookItemGetOperation! )
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
