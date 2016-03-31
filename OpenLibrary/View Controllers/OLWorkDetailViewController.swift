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

    lazy var queryCoordinator: WorkDetailCoordinator = {
        return
            WorkDetailCoordinator(
                operationQueue: self.operationQueue!,
                coreDataStack: self.coreDataStack!,
                searchInfo: self.searchInfo!,
                workDetailVC: self
            )
    }()
    
    var authorWorksVC: OLWorkDetailEditionsTableViewController?
    var authorEditionsVC: OLWorkDetailEditionsTableViewController?
    
    var currentImageURL: NSURL?
    
    var operationQueue: OperationQueue?
    var coreDataStack: CoreDataStack?

    var searchInfo: OLWorkDetail?

    // MARK: UIViewController
    override func viewDidLoad() {
        
        self.queryCoordinator.updateUI()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "embedWorkEditions" {
            
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

}
