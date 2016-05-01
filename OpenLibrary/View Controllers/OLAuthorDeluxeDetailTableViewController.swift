//
//  OLAuthorDeluxeDetailTableViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/27/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class OLAuthorDeluxeDetailTableViewController: UITableViewController {

    var queryCoordinator: AuthorDeluxeDetailCoordinator?
    
    // MARK: UIView
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.estimatedRowHeight = 68.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }

    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        if let queryCoordinator = queryCoordinator {
            
            cell = queryCoordinator.displayToTableViewCell( tableView, indexPath: indexPath )
        }
        
        return cell!
    }
    
    override func numberOfSectionsInTableView( tableView: UITableView ) -> Int {
    
        var count = 0
    
        if let queryCoordinator = queryCoordinator {
            
            count = queryCoordinator.numberOfSections()
        }
        
        return count
    }
    
    override func tableView( tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        var rows = 0
        if let queryCoordinator = queryCoordinator {
            
            rows = queryCoordinator.numberOfRowsInSection( section )
        }
        
        return rows
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let queryCoordinator = queryCoordinator {
            
            queryCoordinator.didSelectRowAtIndexPath( indexPath )
        }
    }
}
