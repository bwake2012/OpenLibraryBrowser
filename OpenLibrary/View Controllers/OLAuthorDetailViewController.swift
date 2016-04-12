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
    var searchInfo: OLAuthorSearchResult?

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
                queryCoordinator?.setAuthorWorksCoordinator( destVC, searchInfo: searchInfo! )
            }
        } else if segue.identifier == "embedAuthorEditions" {
            
            if let destVC = segue.destinationViewController as? OLAuthorDetailEditionsTableViewController {
                
                self.authorEditionsVC = destVC
                queryCoordinator?.setAuthorEditionsCoordinator( destVC, searchInfo: searchInfo! )

            }
        } else if segue.identifier == "largeAuthorPhoto" {
            
            if let destVC = segue.destinationViewController as? OLPictureViewController {

                queryCoordinator?.setAuthorPictureCoordinator( destVC, searchInfo: searchInfo! )
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
        
        self.displayLargePhoto.enabled = authorDetail.hasImage
            
        self.authorName.text = authorDetail.name
        self.authorPhoto.image = nil
    }
    
    // MARK: Utility

}
