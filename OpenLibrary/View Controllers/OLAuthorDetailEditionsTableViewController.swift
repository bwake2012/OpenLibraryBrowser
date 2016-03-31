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
    var operationQueue: OperationQueue?
    var coreDataStack: CoreDataStack?
    
    var searchInfo: OLAuthorSearchResult?
    lazy var queryCoordinator: AuthorEditionsCoordinator = {
        return
            AuthorEditionsCoordinator(
                    searchInfo: self.searchInfo!,
                    withCoversOnly: true,
                    tableView: self.tableView,
                    coreDataStack: self.coreDataStack!,
                    operationQueue: self.operationQueue!
                )
    }()!
    
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
        
    }
    
    // MARK: UITableViewDelegate
    
    // MARK: UITableviewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return queryCoordinator.numberOfSections() ?? 0
    }
    
    override func tableView( tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        return queryCoordinator.numberOfRowsInSection( section ) ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("editionsEntry", forIndexPath: indexPath) as! WorkEditionTableViewCell
        
        cell.configure( queryCoordinator.objectAtIndexPath( indexPath ) )
        
        return cell
    }
    
    // MARK: Utility
}
