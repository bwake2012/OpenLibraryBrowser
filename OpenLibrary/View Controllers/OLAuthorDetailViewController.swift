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
    
    @IBOutlet weak var activityView: UIActivityIndicatorView!

    var queryCoordinator: AuthorDetailCoordinator?
    var authorWorksVC: OLAuthorDetailWorksTableViewController?
    var authorEditionsVC: OLAuthorDetailEditionsTableViewController?
    
    var currentImageURL: NSURL?
    
    // MARK: UIViewController
    override func viewDidLoad() {

        super.viewDidLoad()
        
//        let refreshControl = UIRefreshControl()
//        refreshControl.addTarget( self, action: #selector( testRefresh ), forControlEvents: .ValueChanged)
//        scrollView.addSubview( refreshControl )

        scrollView.delegate = self
        
        assert( nil != queryCoordinator )
        
        queryCoordinator?.updateUI()
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "embedAuthorWorks" {
            
            if let destVC = segue.destinationViewController as? OLAuthorDetailWorksTableViewController {
                
                self.authorWorksVC = destVC
                queryCoordinator!.installAuthorWorksCoordinator( destVC )
            }
        } else if segue.identifier == "embedAuthorEditions" {
            
            if let destVC = segue.destinationViewController as? OLAuthorDetailEditionsTableViewController {
                
                self.authorEditionsVC = destVC
                queryCoordinator!.installAuthorEditionsCoordinator( destVC )

            }
        } else if segue.identifier == "displayAuthorDeluxeDetail" {
            
            if let destVC = segue.destinationViewController as? OLDeluxeDetailTableViewController {
                
                queryCoordinator!.installAuthorDeluxeDetailCoordinator( destVC )
            }
            
        } else if segue.identifier == "largeAuthorPhoto" {
            
            if let destVC = segue.destinationViewController as? OLPictureViewController {

                queryCoordinator!.installAuthorPictureCoordinator( destVC )
            }
        }
    }
    

//    // MARK: UIRefreshControl
//    func testRefresh( refreshControl: UIRefreshControl ) {
//        
//        refreshControl.attributedTitle = NSAttributedString( string: "Refreshing data..." )
//        
//        queryCoordinator?.refreshQuery( nil )
//        authorWorksVC?.refreshQuery( refreshControl )
//    }
    

    // MARK: Utility
    func displayImage( localURL: NSURL ) -> Bool {
        
        assert( NSThread.isMainThread() )

        currentImageURL = localURL
        if let data = NSData( contentsOfURL: localURL ) {
            if let image = UIImage( data: data ) {
                
                authorPhoto.image = image
                
                headerView.layoutIfNeeded()
                return true
            }
        }
        
        return false
    }

    
    func updateUI( authorDetail: OLAuthorDetail ) {
        
        assert( NSThread.isMainThread() )

        self.displayLargePhoto.enabled = authorDetail.hasImage
        self.displayDeluxeDetail.enabled = authorDetail.hasDeluxeData
            
        self.authorName.text = authorDetail.name
        
        if !authorDetail.hasImage && nil == authorDetail.provisional_date {
            self.authorPhoto.image = nil
        } else {
            self.authorPhoto.image = UIImage( named: "253-person.png" )
        }
        
        self.displayDeluxeDetail.enabled = nil == authorDetail.provisional_date
        
        view.layoutIfNeeded()
        
        let viewHeight = self.view.bounds.height
        
        var minContentHeight = viewHeight - UIApplication.sharedApplication().statusBarFrame.height
        
        minContentHeight -= navigationController?.navigationBar.frame.height ?? 0
        
        let headerViewHeight = headerView.bounds.height
        
        if headerViewHeight > minContentHeight / 2 {
            
            containerViewHeightConstraint.constant = minContentHeight
        }
     }
    
    // MARK: query in progress
    
    func coordinatorIsBusy() -> Void {
        
        activityView?.startAnimating()
    }
    
    func coordinatorIsNoLongerBusy() -> Void {
        
        activityView?.stopAnimating()
    }
    
    // MARK: Utility

}

extension OLAuthorDetailViewController: TransitionSourceImage {
    
    func transitionSourceRectImageView() -> UIImageView? {
        
        return authorPhoto
    }
}

extension OLAuthorDetailViewController: UncoverBottomTransitionSource {
    
    func uncoverSourceRectangle() -> UIView? {
        
        return containerView
    }
}

extension OLAuthorDetailViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging( scrollView: UIScrollView, willDecelerate decelerate: Bool ) {
        
        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Change 10.0 to adjust the distance from bottom
        if maximumOffset - currentOffset <= -10.0 {
            
            authorWorksVC?.queryCoordinator?.nextQueryPage()
            
        } else if currentOffset <= -10.0 {
            
            navigationController?.setNavigationBarHidden( false, animated: true )
        }
    }
}

