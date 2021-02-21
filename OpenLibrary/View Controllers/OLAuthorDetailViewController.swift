//
//  OLAuthorDetailViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/1/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

import CoreData

// import BNRCoreDataStack

class OLAuthorDetailViewController: UIViewController, NetworkActivityIndicator {

    @IBOutlet weak var headerView: OLHeaderView!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var activityView: UIActivityIndicatorView!

    var queryCoordinator: AuthorDetailCoordinator?
    var authorWorksVC: OLAuthorDetailWorksTableViewController?
    
    var currentImageURL: URL?
    
    // MARK: UIViewController
    override func viewDidLoad() {

        super.viewDidLoad()

        assert( nil != queryCoordinator )

        headerView.headerViewDelegate = self
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
            
        } else if segue.identifier == "zoomLargeImage" {
            
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
                
                headerView.image = image
                
                return true
            }
        }
        
        return false
    }

    
    func updateUI( _ authorDetail: OLAuthorDetail ) {
        
        assert( Thread.isMainThread )

        headerView.clearSummary()
        headerView.addSummaryLine( text: authorDetail.name, style: .headline, segueName: "displayAuthorDeluxeDetail" )
        
        if !authorDetail.birth_date.isEmpty {

            headerView.addSummaryLine( text: "Born: " + authorDetail.birth_date.stringWithNonBreakingSpaces(), style: .footnote, segueName: "" )
        }
        if !authorDetail.death_date.isEmpty {
            
            headerView.addSummaryLine( text: "Died: " + authorDetail.death_date.stringWithNonBreakingSpaces(), style: .footnote, segueName: "" )
        }
        
        if !authorDetail.hasImage {
            headerView.image = nil
        } else {
            headerView.image = UIImage( named: authorDetail.defaultImageName )
        }
        
    }
}

extension OLAuthorDetailViewController: TransitionImage {
    
    var transitionRectImageView: UIImageView? {
        
        return headerView.imageView
    }
}

extension OLAuthorDetailViewController: UncoverBottomTransitionSource {
    
    func uncoverSourceRectangle() -> UIView? {
        
        return containerView
    }
}

extension OLAuthorDetailViewController: OLHeaderViewDelegate {
    
    func performSegue( segueName: String, sender: Any? ) {
        
        assert( !segueName.isEmpty )
        
        if !segueName.isEmpty {
            
            super.performSegue( withIdentifier: segueName, sender: sender )
        }
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

