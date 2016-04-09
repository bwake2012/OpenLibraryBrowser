//
//  WorkDetailCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/21/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

import CoreData

import BNRCoreDataStack

let kWorkDetailCache = "workDetailSearch"

class WorkDetailCoordinator: OLQueryCoordinator {
    
    weak var workDetailVC: OLWorkDetailViewController?

    var searchInfo: OLWorkDetail
    
    init(
            operationQueue: OperationQueue,
            coreDataStack: CoreDataStack,
            searchInfo: OLWorkDetail,
            workDetailVC: OLWorkDetailViewController
        ) {
        
        self.searchInfo = searchInfo
        self.workDetailVC = workDetailVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
    }
    
    func updateUI( workDetail: OLWorkDetail ) {
        
        if let workDetailVC = workDetailVC {
            
            workDetailVC.UpdateUI( workDetail )
            
            if workDetail.covers.count > 0 {
                
                let localURL = workDetail.localURL( "B" )
                if !(workDetailVC.displayImage( localURL )) {
                    
                    let url = localURL
                    let imageGetOperation =
                        ImageGetOperation( numberID: workDetail.covers[0], imageKeyName: "id", localURL: url, size: "M", type: "a" ) {
                            
                            dispatch_async( dispatch_get_main_queue() ) {
                                
                                workDetailVC.displayImage( url )
                            }
                    }
                    
                    imageGetOperation.userInitiated = true
                    operationQueue.addOperation( imageGetOperation )
                }
            }
        }
    }
    
    func updateUI() -> Void {
        
        updateUI( searchInfo )
    }
    
    func setWorkDetailEditionsQueryCoordinator( destVC: OLWorkDetailEditionsTableViewController ) {
        
        destVC.queryCoordinator =
            WorkEditionsCoordinator(
                    searchInfo: self.searchInfo,
                    withCoversOnly: true,
                    tableVC: destVC,
                    coreDataStack: self.coreDataStack,
                    operationQueue: self.operationQueue
                )
    }
    
    func setCoverPictureViewCoordinator( destVC: OLPictureViewController ) {
        
        destVC.queryCoordinator =
            CoverPictureViewCoordinator(
                    operationQueue: self.operationQueue,
                    coreDataStack: self.coreDataStack,
                    managedObject: self.searchInfo,
                    pictureVC: destVC
                )

    }
}
