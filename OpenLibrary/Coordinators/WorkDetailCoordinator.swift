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

class WorkDetailCoordinator: NSObject {
    
    weak var workDetailVC: OLWorkDetailViewController?

    var operationQueue: OperationQueue
    var coreDataStack: CoreDataStack
    
    var searchInfo: OLWorkDetail
    
    init(
            operationQueue: OperationQueue,
            coreDataStack: CoreDataStack,
            searchInfo: OLWorkDetail,
            workDetailVC: OLWorkDetailViewController
        ) {
        
        self.operationQueue = operationQueue
        self.coreDataStack = coreDataStack
        self.searchInfo = searchInfo
        self.workDetailVC = workDetailVC

        super.init()

        updateUI( searchInfo )
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
        
        
    }
}
