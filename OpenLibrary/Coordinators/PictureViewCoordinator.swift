//
//  PictureViewCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/6/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

//import BNRCoreDataStack
import PSOperations

class PictureViewCoordinator: OLQueryCoordinator {
    
    weak var pictureVC: OLPictureViewController?
    
    fileprivate var localURL: URL
    fileprivate var imageID: Int = 0
    fileprivate var pictureType = "a"

    var imageGetOperation: ImageGetOperation?
    
    init(
        operationQueue: PSOperationQueue,
        dataStack: OLDataStack,
        localURL: URL,
        imageID: Int,
        pictureType: String,
        pictureVC: OLPictureViewController
    ) {
    
        self.localURL = localURL
        self.imageID = imageID
        self.pictureType = pictureType
    
        self.pictureVC = pictureVC

        super.init( operationQueue: operationQueue, dataStack: dataStack, viewController: pictureVC )
    }
    
    func updateUI() {
        
        if let pictureVC = pictureVC {

            if !( pictureVC.displayImage( localURL ) ) {

                guard libraryIsReachable() else {
                    
                    return
                }
                
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
                            
                            DispatchQueue.main.async {
                                    
                                if let strongSelf = self {

                                    _ = strongSelf.pictureVC?.displayImage( strongSelf.localURL )
                                    strongSelf.imageGetOperation = nil
                                }
                                
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
