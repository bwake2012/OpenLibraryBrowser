//
//  OLAuthorDetailBookTableViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/4/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit
import CoreData

import BNRCoreDataStack

class OLAuthorDetailWorksTableViewController: UITableViewController {

    // MARK: Properties
    var searchInfo: OLAuthorSearchResult?

    var queryCoordinator: AuthorWorksCoordinator?

    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        assert( nil != queryCoordinator )
        
        self.tableView.estimatedRowHeight = 68.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.tableFooterView = UIView(frame: .zero)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if "displayWorkDetail" == segue.identifier {
            
            if let destVC = segue.destinationViewController as? OLWorkDetailViewController {
                
                if let indexPath = self.tableView.indexPathForSelectedRow {

                    queryCoordinator!.installWorkDetailCoordinator( destVC, indexPath: indexPath )
                }
            }
        }
    }
    
    // MARK: UITableViewDelegate
    
    // MARK: UITableviewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return queryCoordinator!.numberOfSections() ?? 0
    }
    
    override func tableView( tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        return queryCoordinator!.numberOfRowsInSection( section ) ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("authorWorksEntry", forIndexPath: indexPath) as! AuthorWorksTableViewCell
        
        queryCoordinator!.displayToCell( cell, indexPath: indexPath )
        
        return cell
    }
    
    // MARK: Utility
}

