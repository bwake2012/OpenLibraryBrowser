//
//  OLAuthorDetailViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/1/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

import CoreData

import BNRCoreDataStack

class OLAuthorDetailViewController: UIViewController {

    @IBOutlet weak var authorName: UILabel!
    @IBOutlet weak var authorPhoto: UIImageView!

    lazy var queryCoordinator: AuthorDetailCoordinator = {
        return
            AuthorDetailCoordinator(
                    operationQueue: self.operationQueue!,
                    coreDataStack: self.coreDataStack!,
                    searchInfo: self.searchInfo!,
                    authorDetailVC: self
                )
    }()
    
    var authorWorksVC: OLAuthorDetailWorksTableViewController?
    var authorEditionsVC: OLAuthorDetailEditionsTableViewController?
    
    var currentImageURL: NSURL?
    
    var operationQueue: OperationQueue?
    var coreDataStack: CoreDataStack?

    var searchInfo: OLAuthorSearchResult.SearchInfo?

    // MARK: UIViewController
    override func viewDidLoad() {

        self.queryCoordinator.updateUI()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "embedAuthorWorks" {
            
            if let destVC = segue.destinationViewController as? OLAuthorDetailWorksTableViewController {
                
                self.authorWorksVC = destVC

                destVC.operationQueue = self.operationQueue
                destVC.coreDataStack = self.coreDataStack
                destVC.searchInfo = self.searchInfo
            }
        } else if segue.identifier == "embedAuthorEditions" {
            
            if let destVC = segue.destinationViewController as? OLAuthorDetailEditionsTableViewController {
                
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
                
                authorPhoto.image = image
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
    
    
    func UpdateUI( authorDetail: OLAuthorDetail ) {
        
        self.authorName.text = authorDetail.name
        
    }
    
    // MARK: Utility

}
