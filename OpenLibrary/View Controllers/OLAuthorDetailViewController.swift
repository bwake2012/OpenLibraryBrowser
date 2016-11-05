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

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var summaryHeight: NSLayoutConstraint!
    
    @IBOutlet weak var authorName: UILabel!
    @IBOutlet weak var birthDate: UILabel!
    @IBOutlet weak var deathDate: UILabel!
    @IBOutlet weak var authorPhoto: AspectRatioImageView!
    @IBOutlet weak var displayLargePhoto: UIButton!
    @IBOutlet weak var displayDeluxeDetail: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var coverSummarySpacing: NSLayoutConstraint!
    
    @IBOutlet weak var activityView: UIActivityIndicatorView!

    var queryCoordinator: AuthorDetailCoordinator?
    var authorWorksVC: OLAuthorDetailWorksTableViewController?
    
    var currentImageURL: URL?
    
    // MARK: UIViewController
    override func viewDidLoad() {

        super.viewDidLoad()

        assert( nil != queryCoordinator )
    }
    
    override func didReceiveMemoryWarning() {

        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear( animated )
        
        navigationController?.setNavigationBarHidden( false, animated: animated )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear( animated )
        
        queryCoordinator?.updateUI()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "embedAuthorWorks" {
            
            if let destVC = segue.destination as? OLAuthorDetailWorksTableViewController {
                
                self.authorWorksVC = destVC
                queryCoordinator!.installAuthorWorksCoordinator( destVC )
            }

        } else if segue.identifier == "displayAuthorDeluxeDetail" {
            
            if let destVC = segue.destination as? OLDeluxeDetailTableViewController {
                
                queryCoordinator!.installAuthorDeluxeDetailCoordinator( destVC )
            }
            
        } else if segue.identifier == "largeAuthorPhoto" {
            
            if let destVC = segue.destination as? OLPictureViewController {

                queryCoordinator!.installAuthorPictureCoordinator( destVC )
            }
        }
    }

    // MARK: Utility
    @discardableResult func displayImage( _ localURL: URL ) -> Bool {
        
        assert( Thread.isMainThread )

        currentImageURL = localURL
        if let data = try? Data( contentsOf: localURL ) {
            if let image = UIImage( data: data ) {
                
                authorPhoto.image = image
                
                authorPhoto.superview?.layoutIfNeeded()
                return true
            }
        }
        
        return false
    }

    
    func updateUI( _ authorDetail: OLAuthorDetail ) {
        
        assert( Thread.isMainThread )

        self.displayLargePhoto.isEnabled = authorDetail.hasImage

        self.displayDeluxeDetail.isEnabled = !authorDetail.isProvisional
        authorName.textColor = displayDeluxeDetail.currentTitleColor
        
        self.authorName.text = authorDetail.name
        
        self.birthDate.text =
            authorDetail.birth_date.isEmpty ? nil : "Born: " + authorDetail.birth_date.stringWithNonBreakingSpaces()
        self.deathDate.text =
            authorDetail.death_date.isEmpty ? nil : "Died: " + authorDetail.death_date.stringWithNonBreakingSpaces()
        
        if !authorDetail.hasImage && !authorDetail.isProvisional {
            
            var totalTextHeight = authorName.bounds.height
            totalTextHeight += nil == birthDate.text ? 0 : birthDate.bounds.height
            totalTextHeight += nil == deathDate.text ? 0 : deathDate.bounds.height
            
            self.authorPhoto.image = nil
            coverSummarySpacing.constant = 0
            summaryHeight.constant = min( 128, totalTextHeight )
        } else {
            self.authorPhoto.image = UIImage( named: "253-person.png" )
        }
        
        view.layoutIfNeeded()
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
    
    func scrollViewDidEndDragging( _ scrollView: UIScrollView, willDecelerate decelerate: Bool ) {
        
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

    func scrollViewWillEndDragging( _ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint> ) {
        
        // up
        if velocity.y < -1.5 {
            navigationController?.setNavigationBarHidden( false, animated: true )
        }
    }
}

