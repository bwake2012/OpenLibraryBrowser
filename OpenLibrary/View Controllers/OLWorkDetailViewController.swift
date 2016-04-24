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
    @IBOutlet weak var workSubtitle: UILabel!
    @IBOutlet weak var workAuthor: UILabel!
    @IBOutlet weak var workCover: UIImageView!
    @IBOutlet weak var displayLargeCover: UIButton!

    var queryCoordinator: WorkDetailCoordinator?

    var authorWorksVC: OLWorkDetailEditionsTableViewController?
    var authorEditionsVC: OLWorkDetailEditionsTableViewController?
    
    var currentImageURL: NSURL?
    
    var searchInfo: OLWorkDetail?

    // MARK: UIViewController
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        assert( nil != queryCoordinator )
        
        queryCoordinator!.updateUI()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "embedWorkEditions" {
            
            if let destVC = segue.destinationViewController as? OLWorkDetailEditionsTableViewController {
                
                self.authorEditionsVC = destVC
                
                queryCoordinator!.installWorkDetailEditionsQueryCoordinator( destVC )
            }
        } else if segue.identifier == "largeCoverImage" {
            
            if let destVC = segue.destinationViewController as? OLPictureViewController {
                
                queryCoordinator!.installCoverPictureViewCoordinator( destVC )
                
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
    
    
    func updateUI( workDetail: OLWorkDetail, authorName: String ) {
        
        self.workTitle.text = workDetail.title
        self.workSubtitle.text = workDetail.subtitle
        self.workAuthor.text = authorName
        self.displayLargeCover.enabled = workDetail.coversFound
        self.workCover.image = UIImage( named: "96-book.png" )
    }
    
    // MARK: Utility

}

extension OLWorkDetailViewController: ImageViewTransitionSource {
    
    func transitionSourceRectangle() -> UIImageView {
        
        return workCover
    }
}
