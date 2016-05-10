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

    var authorNames = [String]()
    var searchInfo: OLWorkDetail?
    var workKey = ""
    
    init(
            authorNames: [String],
            operationQueue: OperationQueue,
            coreDataStack: CoreDataStack,
            searchInfo: OLWorkDetail,
            workDetailVC: OLWorkDetailViewController
        ) {
        
        self.authorNames = authorNames
        self.searchInfo = searchInfo
        self.workDetailVC = workDetailVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
    }
    
    init(
        authorNames: [String],
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        workKey: String,
        workDetailVC: OLWorkDetailViewController
        ) {
        
        assert( !workKey.isEmpty )
        
        self.authorNames = authorNames
        self.searchInfo = nil
        self.workKey = workKey
        self.workDetailVC = workDetailVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
        
        let workDetailGetOperation =
            WorkDetailGetOperation( queryText: workKey, coreDataStack: coreDataStack, resultHandler: getSearchInfo ) {
                
                [weak self] in
                
                if let strongSelf = self {
                    dispatch_async( dispatch_get_main_queue() ) {
                        
                        strongSelf.updateUI()
                    }
                }
        }
        workDetailGetOperation.userInitiated = true
        operationQueue.addOperation( workDetailGetOperation )
    }
    
    func updateUI( workDetail: OLWorkDetail ) {
        
        if let workDetailVC = workDetailVC {
            
            workDetailVC.updateUI( workDetail, authorName: authorNames.isEmpty ? "" : authorNames[0] )
            
            if workDetail.hasImage {
                
                let localURL = workDetail.localURL( "M" )
                if !( workDetailVC.displayImage( localURL ) ) {

                    let url = localURL
                    let imageGetOperation =
                        ImageGetOperation( numberID: workDetail.covers[0], imageKeyName: "id", localURL: url, size: "M", type: "a" ) {
                            
                            [weak self] in
                            
                            if nil != self {

                                dispatch_async( dispatch_get_main_queue() ) {
                                    
                                    workDetailVC.displayImage( url )
                                }
                            }
                    }
                    
                    imageGetOperation.userInitiated = true
                    operationQueue.addOperation( imageGetOperation )
                    
                    workDetailVC.displayImage( workDetail.localURL( "S" ) )
                }
            }
        }
    }
    
    func updateUI() -> Void {
        
        if let workDetail = searchInfo {
            updateUI( workDetail )
        }
    }
    
    func getSearchInfo( objectID: NSManagedObjectID ) {
        
        dispatch_async( dispatch_get_main_queue() ) {
            if let workDetail = self.coreDataStack.mainQueueContext.objectWithID( objectID ) as? OLWorkDetail {
                
                self.searchInfo = workDetail
            }
        }
    }
    
    // MARK: install query coordinators
    
    func installWorkDetailEditionsQueryCoordinator( destVC: OLWorkDetailEditionsTableViewController ) {
        
        var workKey = self.workKey
        if let workDetail = searchInfo {
            
            workKey = workDetail.key

        }
        
        assert( !workKey.isEmpty )
        
        destVC.queryCoordinator =
            WorkEditionsCoordinator(
                workKey: workKey,
                withCoversOnly: true,
                tableVC: destVC,
                coreDataStack: self.coreDataStack,
                operationQueue: self.operationQueue
        )
     }
    
    func installWorkDeluxeDetailCoordinator( destVC: OLDeluxeDetailTableViewController ) {
        
        guard let workDetail = searchInfo  else {
            assert( false )
            return
        }
        
        destVC.queryCoordinator =
            DeluxeDetailCoordinator(
                operationQueue: operationQueue,
                coreDataStack: coreDataStack,
                deluxeData: workDetail.deluxeData,
                imageType: "b",
                deluxeDetailVC: destVC
        )
    }
    
    func installCoverPictureViewCoordinator( destVC: OLPictureViewController ) {
        
        guard let workDetail = searchInfo  else {
            assert( false )
            return
        }
        
        destVC.queryCoordinator =
            PictureViewCoordinator(
                operationQueue: operationQueue,
                coreDataStack: coreDataStack,
                localURL: workDetail.localURL( "L", index: 0 ),
                imageID: workDetail.firstImageID,
                pictureType: "b",
                pictureVC: destVC
        )

    }
}
