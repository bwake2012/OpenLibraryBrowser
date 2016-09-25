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
    @IBOutlet weak var birthDate: UILabel!
    @IBOutlet weak var deathDate: UILabel!
    @IBOutlet weak var authorPhoto: AspectRatioImageView!
    @IBOutlet weak var displayLargePhoto: UIButton!
    @IBOutlet weak var displayDeluxeDetail: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var activityView: UIActivityIndicatorView!

    var queryCoordinator: AuthorDetailCoordinator?
    var authorWorksVC: OLAuthorDetailWorksTableViewController?
    var authorEditionsVC: OLAuthorDetailEditionsTableViewController?
    
    var currentImageURL: NSURL?
    
    // MARK: UIViewController
    override func viewDidLoad() {

        super.viewDidLoad()

        assert( nil != queryCoordinator )

        queryCoordinator?.updateUI()
    }
    
    override func didReceiveMemoryWarning() {

        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear( animated )
        
        navigationController?.setNavigationBarHidden( false, animated: true )
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

    // MARK: Utility
    func displayImage( localURL: NSURL ) -> Bool {
        
        assert( NSThread.isMainThread() )

        currentImageURL = localURL
        if let data = NSData( contentsOfURL: localURL ) {
            if let image = UIImage( data: data ) {
                
                authorPhoto.image = image
                
                authorPhoto.superview?.layoutIfNeeded()
                return true
            }
        }
        
        return false
    }

    
    func updateUI( authorDetail: OLAuthorDetail ) {
        
        assert( NSThread.isMainThread() )

        self.displayLargePhoto.enabled = authorDetail.hasImage

        self.displayDeluxeDetail.enabled = authorDetail.hasDeluxeData && nil == authorDetail.provisional_date
        authorName.textColor = displayDeluxeDetail.currentTitleColor
        
        self.authorName.text = authorDetail.name
        
        self.birthDate.text =
            authorDetail.birth_date.isEmpty ? "" : "Born: " + authorDetail.birth_date.stringWithNonBreakingSpaces()
        self.deathDate.text =
            authorDetail.death_date.isEmpty ? "" : "Died: " + authorDetail.death_date.stringWithNonBreakingSpaces()
        
        if !authorDetail.hasImage && nil == authorDetail.provisional_date {
            self.authorPhoto.image = nil
        } else {
            self.authorPhoto.image = UIImage( named: "253-person.png" )
        }
        
        view.layoutIfNeeded()
        
        let viewHeight = self.view.bounds.height
        
        var minContentHeight = viewHeight - UIApplication.sharedApplication().statusBarFrame.height
        
        minContentHeight -= navigationController?.navigationBar.frame.height ?? 0
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

