//
//  PictureViewCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/6/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

import BNRCoreDataStack

class PictureViewCoordinator: OLQueryCoordinator {
    
    weak var pictureVC: OLPictureViewController?
    
    var localURL: NSURL
    var imageID: Int = 0
    var pictureType = "a"

    var imageGetOperation: ImageGetOperation?
    
    init(
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        localURL: NSURL,
        imageID: Int,
        pictureType: String,
        pictureVC: OLPictureViewController
    ) {
    
        self.localURL = localURL
        self.imageID = imageID
        self.pictureType = pictureType
    
        self.pictureVC = pictureVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
    }
    
    func updateUI() {
        
        if let pictureVC = pictureVC {

            if !( pictureVC.displayImage( localURL ) ) {

                if nil == imageGetOperation {
                    imageGetOperation =
                        ImageGetOperation(
                            numberID: imageID,
                            imageKeyName: "id",
                            localURL: localURL,
                            size: "L",
                            type: pictureType
                        ) {
                            [weak self] in
                            
                            if let strongSelf = self {

                                dispatch_async( dispatch_get_main_queue() ) {
                                    
                                    strongSelf.pictureVC?.displayImage( strongSelf.localURL )
                                }
                                
                                strongSelf.imageGetOperation = nil
                            }
                    }
                    
                    imageGetOperation!.userInitiated = true
                    operationQueue.addOperation( imageGetOperation! )
                }
            }
        }
    }
    
    func cancelOperations() {
        
        imageGetOperation?.cancel()
    }
}