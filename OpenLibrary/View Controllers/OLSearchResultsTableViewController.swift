//
//  OLSearchResultsTableViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit
import CoreData

import BNRCoreDataStack

enum SearchType: Int {
    
    case searchAuthor = 0
    case searchTitle = 1
}

class OLSearchResultsTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {

    // MARK: Properties
    lazy var authorSearchCoordinator: AuthorSearchResultsCoordinator = {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        return appDelegate.getAuthorSearchCoordinator( self )
    }()

    lazy var titleSearchCoordinator: TitleSearchResultsCoordinator = {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        return appDelegate.getTitleSearchCoordinator( self )
    }()
    
    var searchController = UISearchController( searchResultsController: nil )
    var searchType: SearchType = .searchAuthor

    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.estimatedRowHeight = 68.0
        self.tableView.rowHeight = UITableViewAutomaticDimension

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.scopeButtonTitles = ["Author", "Title"]
        searchController.searchBar.delegate = self

        searchController.definesPresentationContext = true
        
        tableView.tableHeaderView = searchController.searchBar
        
        searchController.searchBar.sizeToFit()
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let indexPath = self.tableView.indexPathForSelectedRow {
            if segue.identifier == "displayAuthorDetail" {
            
                if let destVC = segue.destinationViewController as? OLAuthorDetailViewController {
                    
                    if let searchResult = authorSearchCoordinator.objectAtIndexPath( indexPath ) {
                        
                        searchController.active = false
                        authorSearchCoordinator.setAuthorDetailCoordinator( destVC, indexPath: indexPath )
                        destVC.searchInfo = searchResult
                        
//                        print( "\(indexPath.row) \(searchResult.key) \(searchResult.name)" )
                    }
                }
            } else if segue.identifier == "displaySearchWorkDetail" {
                
                if let destVC = segue.destinationViewController as? OLWorkDetailViewController {
                    
                    searchController.active = false
                    titleSearchCoordinator.setTitleDetailCoordinator( destVC, indexPath: indexPath )
                }
            }
        }
    }
    
    // MARK: UITableViewDelegate
    
    // MARK: UITableviewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        if .searchAuthor == self.searchType {
            return authorSearchCoordinator.numberOfSections() ?? 1
        } else if .searchTitle == searchType {
            return titleSearchCoordinator.numberOfSections() ?? 1
        } else {
            assert( false )
            return 1
        }
    }
    
    override func tableView( tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        if .searchAuthor == searchType {
            
            return authorSearchCoordinator.numberOfRowsInSection( section ) ?? 0
            
        } else if .searchTitle == searchType {
            
            return titleSearchCoordinator.numberOfRowsInSection( section ) ?? 0
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if .searchAuthor == searchType {

            let authorCell = tableView.dequeueReusableCellWithIdentifier("authorSearchResult", forIndexPath: indexPath) as! AuthorSearchResultTableViewCell
            
            authorSearchCoordinator.displayToCell( authorCell, indexPath: indexPath )
            
            return authorCell

        } else {
            
            let titleCell = tableView.dequeueReusableCellWithIdentifier("titleSearchResult", forIndexPath: indexPath) as! TitleSearchResultTableViewCell
            
            titleSearchCoordinator.displayToCell( titleCell, indexPath: indexPath )
            
            return titleCell
        }
        
    }
    
    // MARK: Search
    
    func getFirstSearchResults( authorName: String, scopeIndex: Int, userInitiated: Bool = true ) {

        if SearchType( rawValue: scopeIndex ) == .searchAuthor {

            authorSearchCoordinator.newQuery( authorName, userInitiated: userInitiated, refreshControl: self.refreshControl )
        
        } else if SearchType( rawValue: scopeIndex ) == .searchTitle {
        
            titleSearchCoordinator.newQuery( authorName, userInitiated: userInitiated, refreshControl: self.refreshControl )
        }
        
        if scopeIndex != searchType.rawValue {
            
            searchType = SearchType( rawValue: scopeIndex )!
            tableView.reloadData()
        }
    }
    
    func clearSearchResults() {
        
        if searchType == .searchAuthor {
            authorSearchCoordinator.clearQuery()
        } else {
            titleSearchCoordinator.clearQuery()
        }
    }
    
    private func updateUI() {
        
        if searchType == .searchAuthor {
            authorSearchCoordinator.updateUI()
        } else {
            titleSearchCoordinator.updateUI()
        }
    }

    // MARK: UISearchBarDelegate
    func searchBarSearchButtonClicked( searchBar: UISearchBar ) {
        
        if let text = searchBar.text {
            
            searchController.active = false
            getFirstSearchResults( text, scopeIndex: searchBar.selectedScopeButtonIndex )
            
        }
    }
    
    func searchBar( searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int ) {
        
//        if let text = searchBar.text {
//            
//            getFirstSearchResults( text, scopeIndex: selectedScope )
//            
//        }
    }
    
    // MARK: UISearchResultsUpdating
    func updateSearchResultsForSearchController( searchController: UISearchController ) {
        
        
    }
}

