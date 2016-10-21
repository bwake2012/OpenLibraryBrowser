//
//  OLAuthorsTableViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 10/14/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

typealias SaveAuthorKey = ( authorKey: String ) -> Void

class OLAuthorsTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var saveAuthorKey: SaveAuthorKey?

    var queryCoordinator: AuthorsCoordinator?
    var busyCount = 0
    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        assert( nil != queryCoordinator )
        
        self.edgesForExtendedLayout = .None
        navigationController?.navigationBar.translucent = false
        
        self.tableView.estimatedRowHeight = 102.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.tableFooterView = OLTableViewHeaderFooterView.createFromNib()

        queryCoordinator?.updateUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        navigationController?.setNavigationBarHidden( false, animated: animated )
        
        super.viewWillAppear( animated )
    }
    
    // MARK: Query in Progress
    func coordinatorIsBusy() -> Void {
        
        if 0 == busyCount {
            
            activityIndicator.startAnimating()
        }
        
        busyCount += 1
    }
    
    func coordinatorIsNoLongerBusy() -> Void {
        
        busyCount -= 1
        if 0 == busyCount {
            
            activityIndicator.stopAnimating()
        }
    }
    
}

extension OLAuthorsTableViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging( scrollView: UIScrollView, willDecelerate decelerate: Bool ) {
        
        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y
        
        if currentOffset <= -10.0 {
            
            navigationController?.setNavigationBarHidden( false, animated: true )
        }
        
    }
    
    func scrollViewWillEndDragging( scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint> ) {
        
        // up
        if velocity.y < -1.5 {
            navigationController?.setNavigationBarHidden( false, animated: true )
        }
    }
}

// MARK: UITableViewDelegate
extension OLAuthorsTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let authorDetail = queryCoordinator?.objectAtIndexPath( indexPath ) {
            
            if let saveAuthorKey = saveAuthorKey {
                
                saveAuthorKey( authorKey: authorDetail.key )
            }
            
            performSegueWithIdentifier( "beginAuthorDetail", sender: self )
        }
    }
}

// MARK: UITableviewDataSource
extension OLAuthorsTableViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return queryCoordinator?.numberOfSections() ?? 0
    }
    
    func tableView( tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        return queryCoordinator?.numberOfRowsInSection( section ) ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AuthorsTableViewCell", forIndexPath: indexPath) as! AuthorsTableViewCell
        
        queryCoordinator?.displayToCell( cell, indexPath: indexPath )
        
        return cell
    }
}

