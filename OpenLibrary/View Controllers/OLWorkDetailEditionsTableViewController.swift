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
        let cell = tableView.dequeueReusableCellWithIdentifier("workEditionEntry", forIndexPath: indexPath)
        if let cell = cell as? WorkEditionTableViewCell {
            
            queryCoordinator!.displayToCell( cell, indexPath: indexPath )
            
        }
        
        
        return cell
    }
    
}

