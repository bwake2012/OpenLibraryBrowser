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

class AuthorDetailCoordinator: NSObject {
    
    weak var authorDetailVC: OLAuthorDetailViewController?

    var operationQueue: OperationQueue?
    var coreDataStack: CoreDataStack?
    
    var searchInfo: OLAuthorSearchResult
    
    init(
            operationQueue: OperationQueue,
            coreDataStack: CoreDataStack,
            searchInfo: OLAuthorSearchResult,
            authorDetailVC: OLAuthorDetailViewController
        ) {
        
        self.operationQueue = operationQueue
        self.coreDataStack = coreDataStack
        self.searchInfo = searchInfo
        self.authorDetailVC = authorDetailVC

        super.init()

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
                                    
                                    if let detail = searchInfo.toDetail {
                                        
                                        strongSelf.updateUI( detail )
                                    }
                                }
                            }
                        }

            getAuthorOperation.userInitiated = true
            operationQueue.addOperation( getAuthorOperation )
        }
    }
    
    
    func updateUI( authorDetail: OLAuthorDetail ) {
        
        if let authorDetailVC = authorDetailVC {
            
            authorDetailVC.UpdateUI( authorDetail )
            
            if authorDetail.photos.count > 0 {
                
                let localURL = authorDetail.localURL( "M" )
                if !(authorDetailVC.displayImage( localURL )) {
                    
                    let url = localURL
                    let imageGetOperation =
                        ImageGetOperation( numberID: authorDetail.photos[0], imageKeyName: "ID", localURL: url, size: "M", type: "a" ) {
                            
                            dispatch_async( dispatch_get_main_queue() ) {
                                
                                authorDetailVC.displayImage( url )
                            }
                    }
                    
                    imageGetOperation.userInitiated = true
                    operationQueue!.addOperation( imageGetOperation )
                }
            }
        }
    }

    
    func updateUI() -> Void {
        
        
    }
}
