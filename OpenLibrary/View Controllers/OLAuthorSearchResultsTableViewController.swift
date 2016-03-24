//
//  OLAuthorSearchResultsTableviewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit
import CoreData

import BNRCoreDataStack

class OLAuthorSearchResultsTableViewController: UITableViewController {

    // MARK: Properties
    var coreDataStack: CoreDataStack?
    
    var operationQueue: OperationQueue?
    
    var queryCoordinator: AuthorSearchResultsCoordinator?

    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        queryCoordinator =
            AuthorSearchResultsCoordinator(
                    tableView: self.tableView,
                    coreDataStack: self.coreDataStack!,
                    operationQueue: self.operationQueue!
                )
                
        self.tableView.estimatedRowHeight = 68.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "displayAuthorDetail" {
            
            if let indexPath = self.tableView.indexPathForSelectedRow {
                if let destVC = segue.destinationViewController as? OLAuthorDetailViewController {
                    
                    if let searchResult = queryCoordinator?.objectAtIndexPath( indexPath ) {
                        destVC.operationQueue = self.operationQueue
                        destVC.coreDataStack = self.coreDataStack
                        destVC.searchInfo = searchResult.searchInfo
                        
                        print( "\(indexPath.row) \(searchResult.key) \(searchResult.name)" )
                    }
                }
            }
        }
    }
    
    // MARK: UITableViewDelegate
    
    // MARK: UITableviewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return queryCoordinator?.numberOfSections() ?? 0
    }
    
    override func tableView( tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        return queryCoordinator?.numberOfRowsInSection( section ) ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("authorSearchResult", forIndexPath: indexPath) as! AuthorSearchResultTableViewCell
        
        queryCoordinator?.displayToCell( cell, indexPath: indexPath )
        
        return cell
    }
    
    // MARK: Search
    
    func getFirstAuthorSearchResults( authorName: String, userInitiated: Bool = true ) {

        if let qc = queryCoordinator {

            qc.newQuery( authorName, userInitiated: userInitiated, refreshControl: self.refreshControl )
        }
        else {
            /*
            We don't have a queryCoordinator to operate on, so wait a bit 
            and just make the refresh control end.
            */
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC)))
            dispatch_after(when, dispatch_get_main_queue()) {
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    private func updateUI() {
        
        queryCoordinator?.updateUI()
    }
}
