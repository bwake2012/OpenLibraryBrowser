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
    
    lazy var queryCoordinator: AuthorSearchResultsCoordinator = {
        
        let coordinator =
            AuthorSearchResultsCoordinator(
                    tableView: self.tableView,
                    coreDataStack: self.coreDataStack!,
                    operationQueue: self.operationQueue!
                )
        
        return coordinator!
    }()

    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
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
                    
                    if let searchResult = queryCoordinator.objectAtIndexPath( indexPath ) {
                        destVC.operationQueue = self.operationQueue
                        destVC.coreDataStack = self.coreDataStack
                        destVC.searchInfo = searchResult
                        
                        print( "\(indexPath.row) \(searchResult.key) \(searchResult.name)" )
                    }
                }
            }
        }
    }
    
    // MARK: UITableViewDelegate
    
    // MARK: UITableviewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return queryCoordinator.numberOfSections() ?? 1
    }
    
    override func tableView( tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        return queryCoordinator.numberOfRowsInSection( section ) ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("authorSearchResult", forIndexPath: indexPath) as! AuthorSearchResultTableViewCell
        
        queryCoordinator.displayToCell( cell, indexPath: indexPath )
        
        return cell
    }
    
    // MARK: Search
    
    func getFirstAuthorSearchResults( authorName: String, userInitiated: Bool = true ) {

        queryCoordinator.newQuery( authorName, userInitiated: userInitiated, refreshControl: self.refreshControl )
    }
    
    func clearSearchResults() {
        
        queryCoordinator.clearQuery()
    }
    
    private func updateUI() {
        
        queryCoordinator.updateUI()
    }
}
