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

class OLWorkDetailEditionsTableViewController: UITableViewController {

    // MARK: Properties
    var searchInfo: OLWorkDetail?

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
    
    // MARK: UIScrollViewController
    
    override func scrollViewDidEndDragging( scrollView: UIScrollView, willDecelerate decelerate: Bool ) {
        
        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Change 10.0 to adjust the distance from bottom
        if maximumOffset - currentOffset <= 10.0 {
            
            queryCoordinator?.nextQueryPage()
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
    

    
    // MARK: UITableViewDelegate
    
    // MARK: UITableviewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return queryCoordinator!.numberOfSections()
    }
    
    override func tableView( tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        return queryCoordinator!.numberOfRowsInSection( section )
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("workEditionEntry", forIndexPath: indexPath)
        if let cell = cell as? WorkEditionTableViewCell {
            
            queryCoordinator!.displayToCell( cell, indexPath: indexPath )
            
        }
        
        return cell
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

