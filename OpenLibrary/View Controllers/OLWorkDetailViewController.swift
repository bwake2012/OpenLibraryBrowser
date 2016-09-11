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
    
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
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
        
//        let refreshControl = UIRefreshControl()
//        refreshControl.addTarget( self, action: #selector( testRefresh ), forControlEvents: .ValueChanged)
//        scrollView.addSubview( refreshControl )
        scrollView.delegate = self
        
        assert( nil != queryCoordinator )
        
        queryCoordinator!.updateUI()
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                
                queryCoordinator!.installWorkDeluxeDetailCoordinator( destVC )
            }
            
        } else if segue.identifier == "displayAuthorDetail" {
            
            if let destVC = segue.destinationViewController as? OLAuthorDetailViewController {
                
                queryCoordinator!.installAuthorDetailCoordinator( destVC )
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
    
    // MARK: query in progress
    
    func coordinatorIsBusy() -> Void {
        
        activityView?.startAnimating()
    }
    
    func coordinatorIsNoLongerBusy() -> Void {
        
        activityView?.stopAnimating()
    }
    
    
    func displayImage( localURL: NSURL ) -> Bool {
        
        assert( NSThread.isMainThread() )

        guard nil == currentImageURL || localURL == currentImageURL else { return true }
        
        assert( NSThread.isMainThread() )

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
        
        assert( NSThread.isMainThread() )

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
        
        assert( NSThread.isMainThread() )

        self.workTitle.text = workDetail.title
        self.workSubtitle.text = workDetail.subtitle
        self.workAuthor.text = workDetail.author_names.joinWithSeparator( ", " )
        self.displayLargeCover.enabled = workDetail.coversFound
        if !workDetail.coversFound {
            self.workCover.image = nil
        } else {
            self.workCover.image = UIImage( named: workDetail.defaultImageName )
        }

        self.displayDeluxeDetail.enabled = nil == workDetail.provisional_date
        workTitle.textColor = displayDeluxeDetail.currentTitleColor
        workSubtitle.textColor = displayDeluxeDetail.currentTitleColor

        self.displayAuthorDetail.enabled = !workDetail.author_names.isEmpty
        
        view.layoutIfNeeded()
        
        let viewHeight = self.view.bounds.height
        
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.height
        let navBarHeight = self.navigationController?.navigationBar.frame.height ?? 0
        let minContentHeight = viewHeight - ( statusBarHeight + navBarHeight )
        
        let headerViewHeight = headerView.bounds.height
        
        if headerViewHeight > minContentHeight / 2 {
            
            containerViewHeightConstraint.constant = minContentHeight
        }
        
    }
    
    // MARK: Utility

}

extension OLWorkDetailViewController: TransitionSourceImage {
    
    func transitionSourceRectImageView() -> UIImageView? {
        
        return workCover
    }
}

extension OLWorkDetailViewController: UncoverBottomTransitionSource {
    
    func uncoverSourceRectangle() -> UIView? {
        
        return containerView
    }
}

extension OLWorkDetailViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging( scrollView: UIScrollView, willDecelerate decelerate: Bool ) {
        
        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Change 10.0 to adjust the distance from bottom
        if maximumOffset - currentOffset <= -10.0 {
            
            workEditionsVC?.queryCoordinator?.nextQueryPage()
            
        } else if currentOffset <= -10.0 {
            
            navigationController?.setNavigationBarHidden( false, animated: true )
        }
        
    }
}


