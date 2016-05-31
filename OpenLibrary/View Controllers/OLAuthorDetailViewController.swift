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

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var authorName: UILabel!
    @IBOutlet weak var authorPhoto: AspectRatioImageView!
    @IBOutlet weak var displayLargePhoto: UIButton!
    @IBOutlet weak var displayDeluxeDetail: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!

    var queryCoordinator: AuthorDetailCoordinator?
    var authorWorksVC: OLAuthorDetailWorksTableViewController?
    var authorEditionsVC: OLAuthorDetailEditionsTableViewController?
    
    var currentImageURL: NSURL?
    
    // MARK: UIViewController
    override func viewDidLoad() {

        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget( self, action: #selector( testRefresh ), forControlEvents: .ValueChanged)
        scrollView.addSubview( refreshControl )

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
        } else if segue.identifier == "displayAuthorDeluxeDetail" {
            
            if let destVC = segue.destinationViewController as? OLDeluxeDetailTableViewController {
                
                queryCoordinator?.installAuthorDeluxeDetailCoordinator( destVC )
            }
            
        } else if segue.identifier == "largeAuthorPhoto" {
            
            if let destVC = segue.destinationViewController as? OLPictureViewController {

                queryCoordinator?.installAuthorPictureCoordinator( destVC )
            }
        }
    }
    

    // MARK: UIRefreshControl
    func testRefresh( refreshControl: UIRefreshControl ) {
        
        refreshControl.attributedTitle = NSAttributedString( string: "Refreshing data..." )
        
        queryCoordinator?.refreshQuery( nil )
        authorWorksVC?.refreshQuery( refreshControl )
    }
    

    // MARK: Utility
    func displayImage( localURL: NSURL ) -> Bool {
        
        currentImageURL = localURL
        if let data = NSData( contentsOfURL: localURL ) {
            if let image = UIImage( data: data ) {
                
                authorPhoto.image = image
                return true
            }
        }
        
        return false
    }

    
    func updateUI( authorDetail: OLAuthorDetail ) {
        
        self.displayLargePhoto.enabled = authorDetail.hasImage
        self.displayDeluxeDetail.enabled = authorDetail.hasDeluxeData
            
        self.authorName.text = authorDetail.name
        
        if !authorDetail.hasImage {
            self.authorPhoto.image = nil
        } else {
            self.authorPhoto.image = UIImage( named: "253-person.png" )
        }
        
        self.displayDeluxeDetail.enabled = true
        
        view.layoutIfNeeded()
        
        let viewHeight = self.view.bounds.height
        
        let minContentHeight = viewHeight - UIApplication.sharedApplication().statusBarFrame.height +
            self.navigationController!.navigationBar.frame.height
        
        let headerViewHeight = headerView.bounds.height
        
        if headerViewHeight > minContentHeight / 2 {
            
            containerViewHeightConstraint.constant = minContentHeight
        }
     }
    
    // MARK: Utility

}

extension OLAuthorDetailViewController: ImageViewTransitionSource {
    
    func transitionSourceRectangle() -> UIImageView? {
        
        return authorPhoto
    }
}

extension OLAuthorDetailViewController: UncoverBottomTransitionSource {
    
    func uncoverSourceRectangle() -> UIView? {
        
        return containerView
    }
}

