//
//  CoverPictureViewCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/6/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

import BNRCoreDataStack

class CoverPictureViewCoordinator: OLQueryCoordinator, PictureViewCoordinatorProtocol {
    
    weak var pictureVC: OLPictureViewController?
    
    var managedObject: OLManagedObject
    
    init(
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        managedObject: OLManagedObject,
        pictureVC: OLPictureViewController
        ) {
        
        self.managedObject = managedObject
        
        self.pictureVC = pictureVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
    }
    
    func updateUI() {
        
        if managedObject.hasImage {
            
            let url = managedObject.localURL( "L" )
            
            if let pictureVC = pictureVC {

                if !(pictureVC.displayImage( url )) {
                    
                    updateUI( managedObject, localURL: url )
                        
                }
            }
        }
    }
    
    func updateUI( managedObject: OLManagedObject, localURL: NSURL ) {
        
        if managedObject.hasImage {
            
            if let pictureVC = pictureVC {
                
                let imageGetOperation =
                    ImageGetOperation( numberID: managedObject.firstImageID, imageKeyName: "ID", localURL: localURL, size: "L", type: "b" ) {
                        
                        dispatch_async( dispatch_get_main_queue() ) {
                            
                            pictureVC.displayImage( localURL )
                        }
                }
                
                imageGetOperation.userInitiated = true
                operationQueue.addOperation( imageGetOperation )
            }
        }
    }
    
    
    
}