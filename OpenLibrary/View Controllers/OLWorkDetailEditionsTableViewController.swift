//
//  OLWorkDetailEditionsTableViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/4/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit
import CoreData

import BNRCoreDataStack

class OLWorkDetailEditionsTableViewController: UIViewController {

    // MARK: Properties
    var searchInfo: OLWorkDetail?

    @IBOutlet var tableView: UITableView!
    var queryCoordinator: WorkEditionsCoordinator?
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        assert( nil != queryCoordinator )
        
        self.tableView.estimatedRowHeight = 68.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.tableFooterView = OLTableViewHeaderFooterView.createFromNib()

        queryCoordinator?.updateUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        // Dynamic sizing for the header view
        if let footerView = tableView.tableFooterView {
            let height = footerView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            var footerFrame = footerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get
            // repeatedly, causing the app to hang.
            if height != footerFrame.size.height {
                footerFrame.size.height = height
                footerView.frame = footerFrame
                tableView.tableFooterView = footerView
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "displayEditionDetail" {
            
            if let destVC = segue.destinationViewController as? OLEditionDetailViewController {
                
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    queryCoordinator!.installEditionCoordinator( destVC, indexPath: indexPath )
                    
                }
            }
        } else if segue.identifier == "displayEditionDeluxeDetail" {
            
            if let destVC = segue.destinationViewController as? OLDeluxeDetailTableViewController {
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    
                    queryCoordinator!.installEditionDeluxeCoordinator( destVC, indexPath: indexPath )
                }
            }
        }
    }
    
    // MARK: Query in Progress
    func coordinatorIsBusy() -> Void {
        
        if let parentVC = parentViewController as? OLWorkDetailViewController {

            parentVC.coordinatorIsBusy()
        }
    }
    
    func coordinatorIsNoLongerBusy() -> Void {
        
        if let parentVC = parentViewController as? OLWorkDetailViewController {
            
            parentVC.coordinatorIsNoLongerBusy()
        }
    }
    
    
    
    func refreshQuery( refreshControl: UIRefreshControl? ) {
        
        queryCoordinator?.refreshQuery( refreshControl )
    }
}

extension OLWorkDetailEditionsTableViewController: TransitionSourceCell {
    
    func transitionSourceRectCellView() -> UITableViewCell? {
        
        var sourceRectView: UITableViewCell?
        
        if let indexPath = tableView.indexPathForSelectedRow {
            
            sourceRectView = tableView.cellForRowAtIndexPath( indexPath )
        }
        
        return sourceRectView
    }
    
}

// MARK: UIScrollViewDelegate

extension OLWorkDetailEditionsTableViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging( scrollView: UIScrollView, willDecelerate decelerate: Bool ) {
        
        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Change 10.0 to adjust the distance from bottom
        if maximumOffset - currentOffset <= -10.0 {
            
            queryCoordinator?.nextQueryPage()
            
        } else if currentOffset <= -10.0 {
            
            navigationController?.setNavigationBarHidden( false, animated: true )
        }
        
    }
}

// MARK: UITableViewDelegate
extension OLWorkDetailEditionsTableViewController: UITableViewDelegate {
    
}

// MARK: UITableviewDataSource
extension OLWorkDetailEditionsTableViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return queryCoordinator!.numberOfSections()
    }
    
    func tableView( tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        return queryCoordinator!.numberOfRowsInSection( section )
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("workEditionEntry", forIndexPath: indexPath)
        if let cell = cell as? WorkEditionTableViewCell {
            
            queryCoordinator!.displayToCell( cell, indexPath: indexPath )
            
        }
        
        return cell
    }
}
