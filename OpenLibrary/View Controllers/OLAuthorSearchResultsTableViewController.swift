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

class OLAuthorSearchResultsTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {

    // MARK: Properties
    lazy var queryCoordinator: AuthorSearchResultsCoordinator = {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        return appDelegate.getAuthorSearchCoordinator( self )
    }()

    var searchController = UISearchController( searchResultsController: nil )

    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        self.tableView.estimatedRowHeight = 68.0
        self.tableView.rowHeight = UITableViewAutomaticDimension

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.definesPresentationContext = true
        searchController.searchBar.scopeButtonTitles = ["Author", "Title" ]
        searchController.searchBar.delegate = self
        
        tableView.tableHeaderView = searchController.searchBar
        
        searchController.searchBar.sizeToFit()
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
                        
                        queryCoordinator.setAuthorDetailCoordinator( destVC, indexPath: indexPath )
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
    
    func getFirstSearchResults( authorName: String, scopeIndex: Int, userInitiated: Bool = true ) {

        queryCoordinator.newQuery( authorName, userInitiated: userInitiated, refreshControl: self.refreshControl )
    }
    
    func clearSearchResults() {
        
        queryCoordinator.clearQuery()
    }
    
    private func updateUI() {
        
        queryCoordinator.updateUI()
    }

    // MARK: UISearchBarDelegate
    func searchBarSearchButtonClicked( searchBar: UISearchBar ) {
        
        if let text = searchBar.text {
            
            getFirstSearchResults( text, scopeIndex: searchBar.selectedScopeButtonIndex )
            
        }
    }
    
    func searchBar( searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int ) {
        
        if let text = searchBar.text {
            
            getFirstSearchResults( text, scopeIndex: selectedScope )
            
        }
    }
    
    // MARK: UISearchResultsUpdating
    func updateSearchResultsForSearchController( searchController: UISearchController ) {
        
        
    }
}
