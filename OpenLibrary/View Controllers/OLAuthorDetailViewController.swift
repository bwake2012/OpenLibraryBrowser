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
    @IBOutlet weak var displayLargePhoto: UIButton!

    var queryCoordinator: AuthorDetailCoordinator?
    var authorWorksVC: OLAuthorDetailWorksTableViewController?
    var authorEditionsVC: OLAuthorDetailEditionsTableViewController?
    
    var currentImageURL: NSURL?
    
    // MARK: UIViewController
    override func viewDidLoad() {

        super.viewDidLoad()
        
        assert( nil != queryCoordinator )
        
        self.queryCoordinator!.updateUI()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "embedAuthorWorks" {
            
            if let destVC = segue.destinationViewController as? OLAuthorDetailWorksTableViewController {
                
                self.authorWorksVC = destVC
                queryCoordinator?.installAuthorWorksCoordinator( destVC )
            }
        } else if segue.identifier == "embedAuthorEditions" {
            
            if let destVC = segue.destinationViewController as? OLAuthorDetailEditionsTableViewController {
                
                self.authorEditionsVC = destVC
                queryCoordinator?.installAuthorEditionsCoordinator( destVC )

            }
        } else if segue.identifier == "largeAuthorPhoto" {
            
            if let destVC = segue.destinationViewController as? OLPictureViewController {

                queryCoordinator?.installAuthorPictureCoordinator( destVC )
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
    
    
    func updateUI( authorDetail: OLAuthorDetail ) {
        
        self.displayLargePhoto.enabled = authorDetail.hasImage
            
        self.authorName.text = authorDetail.name
        
        if !authorDetail.hasImage {
            self.authorPhoto.image = UIImage( named: "253-person.png" )
        }
    }
    
    // MARK: Utility

}

extension OLAuthorDetailViewController: ImageViewTransitionSource {
    
    func transitionSourceRectangle() -> UIImageView {
        
        return authorPhoto
    }
}

