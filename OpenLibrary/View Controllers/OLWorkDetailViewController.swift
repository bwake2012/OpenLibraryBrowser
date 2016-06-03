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

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var workTitle: UILabel!
    @IBOutlet weak var workSubtitle: UILabel!
    @IBOutlet weak var workAuthor: UILabel!
    @IBOutlet weak var workCover: UIImageView!
    @IBOutlet weak var displayLargeCover: UIButton!
    @IBOutlet weak var displayDeluxeDetail: UIButton!
    @IBOutlet weak var displayAuthorDetail: UIButton!

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!
    
    var queryCoordinator: WorkDetailCoordinator?

    var workEditionsVC: OLWorkDetailEditionsTableViewController?
    
    var currentImageURL: NSURL?
    
    var searchInfo: OLWorkDetail?
    
    @IBAction func displayAuthorDetail(sender: UIButton) {
        
        if let authorDetailVC = findAuthorDetailInStack( ) {
            
            self.navigationController?.popToViewController( authorDetailVC, animated: true )
            
        } else {
            
            performSegueWithIdentifier( "displayAuthorDetail", sender: self )
        }
    }
    
    // MARK: UIViewController
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget( self, action: #selector( testRefresh ), forControlEvents: .ValueChanged)
        scrollView.addSubview( refreshControl )
        
        assert( nil != queryCoordinator )
        
        queryCoordinator!.updateUI()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "embedWorkEditions" {
            
            if let destVC = segue.destinationViewController as? OLWorkDetailEditionsTableViewController {
                
                self.workEditionsVC = destVC
                
                queryCoordinator!.installWorkDetailEditionsQueryCoordinator( destVC )
            }
        } else if segue.identifier == "largeCoverImage" {
            
            if let destVC = segue.destinationViewController as? OLPictureViewController {
                
                queryCoordinator!.installCoverPictureViewCoordinator( destVC )
                
            }
        } else if segue.identifier == "displayDeluxeWorkDetail" {
            
            if let destVC = segue.destinationViewController as? OLDeluxeDetailTableViewController {
                
                queryCoordinator?.installWorkDeluxeDetailCoordinator( destVC )
            }
            
        } else if segue.identifier == "displayAuthorDetail" {
            
            if let destVC = segue.destinationViewController as? OLAuthorDetailViewController {
                
                queryCoordinator?.installAuthorDetailCoordinator( destVC )
            }
        }
    }

    // MARK: UIRefreshControl
    func testRefresh( refreshControl: UIRefreshControl ) {
        
        refreshControl.attributedTitle = NSAttributedString( string: "Refreshing data..." )
        
        queryCoordinator?.refreshQuery( nil )
        workEditionsVC?.refreshQuery( refreshControl )
    }
    
    
    // MARK: Utility
    func findAuthorDetailInStack() -> OLAuthorDetailViewController? {
        
        if let qc = queryCoordinator, navController = self.navigationController {

            return qc.findAuthorDetailInStack( navController )
        }
        
        return nil
    }
    
    
    func displayImage( localURL: NSURL ) -> Bool {
        
        guard nil == currentImageURL || localURL == currentImageURL else { return true }
        
        currentImageURL = localURL
        if let data = NSData( contentsOfURL: localURL ) {
            if let image = UIImage( data: data ) {
                
                workCover.image = image
                self.displayLargeCover.enabled = true
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
                self.displayLargeCover.enabled = true
                return true
            }
        }
        
        return false
    }
    
    
    func updateUI( workDetail: OLWorkDetail ) {
        
        self.workTitle.text = workDetail.title
        self.workSubtitle.text = workDetail.subtitle
        self.workAuthor.text = workDetail.author_names.joinWithSeparator( ", " )
        self.displayLargeCover.enabled = workDetail.coversFound
        if !workDetail.coversFound {
            self.workCover.image = nil
        } else {
            self.workCover.image = UIImage( named: workDetail.defaultImageName )
        }
        self.displayDeluxeDetail.enabled = true
        self.displayAuthorDetail.enabled = true
        
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

extension OLWorkDetailViewController: ImageViewTransitionSource {
    
    func transitionSourceRectangle() -> UIImageView? {
        
        return workCover
    }
}

extension OLWorkDetailViewController: UncoverBottomTransitionSource {
    
    func uncoverSourceRectangle() -> UIView? {
        
        return containerView
    }
}


