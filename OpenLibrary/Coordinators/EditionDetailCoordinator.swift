//
//  EditionDetailCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/7/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

//import BNRCoreDataStack
import PSOperations

class EditionDetailCoordinator: OLQueryCoordinator {

    let editionDetail: OLEditionDetail
    weak var editionDetailVC: OLEditionDetailViewController?
    var authorDetailGetOperation: PSOperation?
    var ebookItemGetOperation: PSOperation?
    
    init(
        operationQueue: PSOperationQueue,
        dataStack: OLDataStack,
        searchInfo: OLEditionDetail,
        editionDetailVC: OLEditionDetailViewController
    ) {
        self.editionDetail = searchInfo
        self.editionDetailVC = editionDetailVC
        
        super.init( operationQueue: operationQueue, dataStack: dataStack, viewController: editionDetailVC )
    }
    
    func updateUI( _ editionDetail: OLEditionDetail ) {
        
        assert( Thread.isMainThread )
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
                            
                            DispatchQueue.main.async {
                                
                                _ = editionDetailVC.displayImage( url )
                            }
                    }
                    
                    imageGetOperation.userInitiated = true
                    operationQueue.addOperation( imageGetOperation )

                    _ = editionDetailVC.displayImage( editionDetail.localURL( "S" ) )
                }
            }
        }
    }
    
    func updateUI() -> Void {
        
        updateUI( editionDetail )
    }
    
    func retrieveAuthors ( _ editionDetail: OLEditionDetail ) {
        
        if editionDetail.author_names.count < editionDetail.authors.count {
            
            newAuthorQueries( editionDetail )
        }
    }
    
    func newAuthorQueries( _ editionDetail: OLEditionDetail ) {
        
        if nil == authorDetailGetOperation {
            
            var authors = editionDetail.authors
            
            let firstOLID = authors.removeFirst()
            
            for olid in authors {
                
                if !olid.isEmpty {
                    let operation =
                        AuthorDetailGetOperation(
                            queryText: olid,
                            parentObjectID: nil,
                            dataStack: dataStack
                        ) {}
                    operationQueue.addOperation( operation )
                }
            }
            
            if !firstOLID.isEmpty {
                
                authorDetailGetOperation =
                    AuthorDetailGetOperation(
                        queryText: firstOLID,
                        parentObjectID: nil,
                        dataStack: dataStack
                    ) {
                        
                        [weak self] in

                        DispatchQueue.main.async {
                                
                           if let strongSelf = self {

                                strongSelf.updateUI( editionDetail )
                                
                                strongSelf.authorDetailGetOperation = nil
                            }
                        }
                }
                operationQueue.addOperation( authorDetailGetOperation! )
            }
        }
    }
    
    func retrieveEBookItems ( _ editionDetail: OLEditionDetail ) {
        
        if editionDetail.mayHaveFullText && editionDetail.ebook_items.isEmpty  {
            
            newEbookItemQuery( editionDetail )
        }
    }
    
    func newEbookItemQuery( _ editionDetail: OLEditionDetail ) {
        
        if nil == ebookItemGetOperation {
            
            ebookItemGetOperation =
                IAEBookItemGetOperation(
                    editionKey: editionDetail.key,
                    dataStack: dataStack
                ) {
                    
                    [weak self] in
                    
                    DispatchQueue.main.async {
                            
                        if let strongSelf = self {
                            
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
    
    func installCoverPictureViewCoordinator( _ destVC: OLPictureViewController ) {

        destVC.queryCoordinator =
            PictureViewCoordinator(
                    operationQueue: self.operationQueue,
                    dataStack: dataStack,
                    localURL: self.editionDetail.localURL( "L", index: 0 ),
                    imageID: self.editionDetail.firstImageID,
                    pictureType: "b",
                    pictureVC: destVC
                )
    }
}
