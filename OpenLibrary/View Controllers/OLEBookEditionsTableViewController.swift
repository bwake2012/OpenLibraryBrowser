//
//  OLEBookEditionsTableViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 7/20/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class OLEBookEditionsTableViewController: UITableViewController {

    var queryCoordinator: EBookEditionsCoordinator?
    
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
        
        if let segueName = segue.identifier {
            
            if segueName == "EbookEditionTableViewCell" {
                
                if let destVC = segue.destinationViewController as? OLBookDownloadViewController {
                    
                    queryCoordinator!.installBookDownloadCoordinator( destVC )
                }
            }
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
        let cell = tableView.dequeueReusableCellWithIdentifier("EbookEditionTableViewCell", forIndexPath: indexPath)
        if let cell = cell as? EbookEditionTableViewCell {
            
            queryCoordinator!.displayToCell( cell, indexPath: indexPath )
            
        }
        
        return cell
    }
    
    func refreshQuery( refreshControl: UIRefreshControl? ) {
        
        queryCoordinator?.refreshQuery( refreshControl )
    }
}
