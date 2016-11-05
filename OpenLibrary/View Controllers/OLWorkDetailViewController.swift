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

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var summaryView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var workTitle: UILabel!
    @IBOutlet weak var workSubtitle: UILabel!
    @IBOutlet weak var workAuthor: UILabel!
    @IBOutlet weak var workCover: UIImageView!
    @IBOutlet weak var displayLargeCover: UIButton!
    @IBOutlet weak var displayDeluxeDetail: UIButton!
    @IBOutlet weak var coverSummarySpacing: NSLayoutConstraint!

    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    var queryCoordinator: WorkDetailCoordinator?

    var workEditionsVC: OLWorkDetailEditionsTableViewController?
    
    var currentImageURL: URL?
    
    var searchInfo: OLWorkDetail?
    
    @IBAction func displayAuthorDetail(_ sender: UIButton) {
        
        performSegue( withIdentifier: "displayAuthorDetail", sender: self )
    }
    
    // MARK: UIViewController
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
//        let refreshControl = UIRefreshControl()
//        refreshControl.addTarget( self, action: #selector( testRefresh ), forControlEvents: .ValueChanged)
//        scrollView.addSubview( refreshControl )
//        scrollView.delegate = self
        
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
        
        if segue.identifier == "embedWorkEditions" {
            
            if let destVC = segue.destination as? OLWorkDetailEditionsTableViewController {
                
                self.workEditionsVC = destVC
                
                queryCoordinator!.installWorkDetailEditionsQueryCoordinator( destVC )
            }

        } else if segue.identifier == "embedWorkEBooks" {
            
            if let destVC = segue.destination as? OLEBookEditionsTableViewController {
                
                queryCoordinator!.installEBookEditionsCoordinator( destVC  )
            }
        
        } else if segue.identifier == "largeCoverImage" {
            
            if let destVC = segue.destination as? OLPictureViewController {
                
                queryCoordinator!.installCoverPictureViewCoordinator( destVC )
                
            }
        } else if segue.identifier == "displayDeluxeWorkDetail" {
            
            if let destVC = segue.destination as? OLDeluxeDetailTableViewController {
                
                queryCoordinator!.installWorkDeluxeDetailCoordinator( destVC )
            }
            
        } else if segue.identifier == "displayAuthorDetail" {
            
            if let destVC = segue.destination as? OLAuthorDetailViewController {
                
                queryCoordinator!.installAuthorDetailCoordinator( destVC )
            }
        }
    }

    // MARK: UIRefreshControl
    func testRefresh( _ refreshControl: UIRefreshControl ) {
        
        refreshControl.attributedTitle = NSAttributedString( string: "Refreshing data..." )
        
        queryCoordinator?.refreshQuery( nil )
        workEditionsVC?.refreshQuery( refreshControl )
    }
    
    // MARK: Utility

    // MARK: query in progress
    
    func coordinatorIsBusy() -> Void {
        
        activityView?.startAnimating()
    }
    
    func coordinatorIsNoLongerBusy() -> Void {
        
        activityView?.stopAnimating()
    }
    
    
    func displayImage( _ localURL: URL ) -> Bool {
        
        assert( Thread.isMainThread )

        guard nil == currentImageURL || localURL == currentImageURL else { return true }
        
        assert( Thread.isMainThread )

        currentImageURL = localURL
        if let data = try? Data( contentsOf: localURL ) {
            if let image = UIImage( data: data ) {
                
                workCover.image = image
                self.displayLargeCover.isEnabled = true
                return true
            }
        }
        
        return false
    }

    func displayImageFromLocalURL( _ localURL: URL, imageView: UIImageView ) -> Bool {
        
        guard nil == currentImageURL || localURL == currentImageURL else { return true }
        
        assert( Thread.isMainThread )

        currentImageURL = localURL
        if let data = try? Data( contentsOf: localURL ) {
            if let image = UIImage( data: data ) {
                
                imageView.image = image
                self.displayLargeCover.isEnabled = true
                return true
            }
        }
        
        return false
    }
    
    
    func updateUI( _ workDetail: OLWorkDetail ) {
        
        assert( Thread.isMainThread )

        workTitle.text = workDetail.title
        workSubtitle.text = workDetail.subtitle
        workAuthor.text = workDetail.author_names.joined( separator: ", " )
        displayLargeCover.isEnabled = workDetail.coversFound
        if !workDetail.coversFound {
            workCover.image = nil
            coverSummarySpacing.constant = 0
        } else {
            workCover.image = UIImage( named: workDetail.defaultImageName )
        }

        displayDeluxeDetail.isEnabled = !workDetail.isProvisional
        workTitle.textColor = displayDeluxeDetail.currentTitleColor
        workSubtitle.textColor = displayDeluxeDetail.currentTitleColor

        view.layoutIfNeeded()
        
//        print( "header:\(headerView.frame) summary:\(summaryView.frame) scroll: \(scrollView.frame) stack:\(stackView.frame) cover:\(workCover.frame)" )
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
    
    func scrollViewDidEndDragging( _ scrollView: UIScrollView, willDecelerate decelerate: Bool ) {
        
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

    func scrollViewWillEndDragging( _ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint> ) {
        
        // up
        if velocity.y < -1.5 {
            navigationController?.setNavigationBarHidden( false, animated: true )
        }
    }
}


