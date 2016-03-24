//
//  OLWorkDetailViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/1/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

import CoreData

import BNRCoreDataStack

class OLWorkDetailViewController: UIViewController {

    @IBOutlet weak var workTitle: UILabel!
    @IBOutlet weak var workCover: UIImageView!

    var queryCoordinator: WorkDetailCoordinator?
    
    var authorWorksVC: OLWorkDetailEditionsTableViewController?
    var authorEditionsVC: OLWorkDetailEditionsTableViewController?
    
    var currentImageURL: NSURL?
    
    var operationQueue: OperationQueue?
    var coreDataStack: CoreDataStack?

    var searchInfo: OLWorkDetail.SearchInfo?

    // MARK: UIViewController
    override func viewDidLoad() {
      
        configureView()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "embedWorkWorks" {
            
            if let destVC = segue.destinationViewController as? OLWorkDetailEditionsTableViewController {
                
                self.authorWorksVC = destVC

                destVC.operationQueue = self.operationQueue
                destVC.coreDataStack = self.coreDataStack
                destVC.searchInfo = self.searchInfo
            }
        } else if segue.identifier == "embedWorkEditions" {
            
            if let destVC = segue.destinationViewController as? OLWorkDetailEditionsTableViewController {
                
                self.authorEditionsVC = destVC
                
                destVC.operationQueue = self.operationQueue
                destVC.coreDataStack = self.coreDataStack
                destVC.searchInfo = self.searchInfo
            }
        }
    }

    // MARK: Utility
    func displayImage( localURL: NSURL ) -> Bool {
        
        guard nil == currentImageURL || localURL == currentImageURL else { return true }
        
        currentImageURL = localURL
        if let data = NSData( contentsOfURL: localURL ) {
            if let image = UIImage( data: data ) {
                
                workCover.image = image
                return true
            }
        }
        
        return false
    }

    func displayImageFromLocalURL( localURL: NSURL, imageView: UIImageView ) -> Bool {
        
        guard nil == currentImageURL || localURL == currentImageURL else { return true }
        
        currentImageURL = localURL
        if let data = NSData( contentsOfURL: localURL ) {
            if let image = UIImage( data: data ) {
                
                imageView.image = image
                return true
            }
        }
        
        return false
    }
    
    
    func UpdateUI( workDetail: OLWorkDetail ) {
        
        self.workTitle.text = workDetail.title
        
    }
    
    // MARK: Utility
    func configureView() {
        
        if let operationQueue = self.operationQueue, coreDataStack = self.coreDataStack {
            
            self.queryCoordinator =
                WorkDetailCoordinator(
                        operationQueue: operationQueue,
                        coreDataStack: coreDataStack,
                        searchInfo: searchInfo!,
                        workDetailVC: self
                    )
        }
    }

}
