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

class OLAuthorDetailEditionsTableViewController: UITableViewController {

    // MARK: Properties
    var searchInfo: OLAuthorSearchResult?
    var queryCoordinator: AuthorEditionsCoordinator?

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
        
    }
    
    // MARK: UITableViewDelegate
    
    // MARK: UITableviewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return queryCoordinator?.numberOfSections() ?? 0
    }
    
    override func tableView( tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        return queryCoordinator!.numberOfRowsInSection( section ) ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("editionsEntry", forIndexPath: indexPath) as! WorkEditionTableViewCell
        
        if let object = queryCoordinator?.objectAtIndexPath( indexPath ) {
            
            cell.configure(
                    tableView,
                    key: object.key,
                    data: object
                )
            
            queryCoordinator?.displayThumbnail( object, cell: cell )
        }
        return cell
    }
    
    // MARK: Utility
}

extension OLAuthorDetailEditionsTableViewController: TransitionSourceCell {
    
    func transitionSourceRectCellView() -> UITableViewCell? {
        
        var sourceRectView: UITableViewCell?
        
        if let indexPath = tableView.indexPathForSelectedRow {
            
            sourceRectView = tableView.cellForRowAtIndexPath( indexPath )
        }
        
        return sourceRectView
    }
    
}

