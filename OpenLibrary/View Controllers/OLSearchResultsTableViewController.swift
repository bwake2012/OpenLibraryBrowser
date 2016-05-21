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
    
    case searchUnknown = -1
    case searchAuthor = 0
    case searchTitle = 1
    case searchGeneral = 2
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
    
    lazy var generalSearchCoordinator: GeneralSearchResultsCoordinator = {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        return appDelegate.getGeneralSearchCoordinator( self )
    }()
    
    var searchController = UISearchController( searchResultsController: nil )
    var searchType: SearchType = .searchAuthor
    var bookSearchVC: OLBookSearchViewController?

    @IBAction func presentGeneralSearch(sender: UIBarButtonItem) {
    }
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
    
    override func viewDidAppear(animated: Bool) {
        
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "openBookSearch" {
            
            if let destVC = segue.destinationViewController as? OLBookSearchViewController {
                if let delegate = segue as? UIViewControllerTransitioningDelegate {
                    
                    destVC.transitioningDelegate = delegate
                    destVC.queryCoordinator = self.generalSearchCoordinator
                    
                    self.bookSearchVC = destVC
                }
            }

        } else {

            if let indexPath = self.tableView.indexPathForSelectedRow {
                if segue.identifier == "displayAuthorDetail" {
                
                    if let destVC = segue.destinationViewController as? OLAuthorDetailViewController {
                        
                        if .searchAuthor == searchType {
                            searchController.active = false
                            authorSearchCoordinator.installAuthorDetailCoordinator( destVC, indexPath: indexPath )
                        } else if .searchGeneral == searchType {
                            generalSearchCoordinator.installAuthorDetailCoordinator( destVC, indexPath: indexPath )
                        }
                    }

                } else if segue.identifier == "displaySearchWorkDetail" {
                    
                    if let destVC = segue.destinationViewController as? OLWorkDetailViewController {
                        
                        searchController.active = false
                        titleSearchCoordinator.installTitleDetailCoordinator( destVC, indexPath: indexPath )
                    }
                } else if segue.identifier == "displayGeneralSearchWorkDetail" {
                    
                    if let destVC = segue.destinationViewController as? OLWorkDetailViewController {
                        
                        searchController.active = false
                        generalSearchCoordinator.installWorkDetailCoordinator( destVC, indexPath: indexPath )
                    }
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
        } else if .searchGeneral == searchType {
            return generalSearchCoordinator.numberOfSections() ?? 1
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

        } else if .searchGeneral == searchType {
            
            return generalSearchCoordinator.numberOfRowsInSection( section ) ?? 0
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell? = nil
        if .searchAuthor == searchType {

            let authorCell = tableView.dequeueReusableCellWithIdentifier("authorSearchResult", forIndexPath: indexPath) as! AuthorSearchResultTableViewCell
            
            authorSearchCoordinator.displayToCell( authorCell, indexPath: indexPath )
            
            cell = authorCell

        } else if .searchTitle == searchType {
            
            let titleCell = tableView.dequeueReusableCellWithIdentifier("titleSearchResult", forIndexPath: indexPath) as! TitleSearchResultTableViewCell
            
            titleSearchCoordinator.displayToCell( titleCell, indexPath: indexPath )
            
            cell = titleCell
            
        } else if .searchGeneral == searchType {
            
            let generalCell = tableView.dequeueReusableCellWithIdentifier( "generalSearchResult", forIndexPath: indexPath) as! GeneralSearchResultTableViewCell
            
            generalSearchCoordinator.displayToCell( generalCell, indexPath: indexPath )
            
            cell = generalCell
        }
     
        return cell!
    }
    
    // MARK: Search
    
    func getFirstSearchResults( authorName: String, scopeIndex: Int, userInitiated: Bool = true ) {

        if SearchType( rawValue: scopeIndex ) == .searchAuthor {

            self.title = "Author"
            authorSearchCoordinator.newQuery( authorName, userInitiated: userInitiated, refreshControl: self.refreshControl )
        
        } else if SearchType( rawValue: scopeIndex ) == .searchTitle {
        
            self.title = "Title"
            titleSearchCoordinator.newQuery( authorName, userInitiated: userInitiated, refreshControl: self.refreshControl )
            
        } else if SearchType( rawValue: scopeIndex ) == .searchGeneral {
            
            self.title = "Search"
        }
        
        searchType = SearchType( rawValue: scopeIndex )!
        tableView.reloadData()
    }
    
    func clearSearchResults() {
        
        if .searchAuthor == searchType {
            authorSearchCoordinator.clearQuery()
        } else if .searchTitle == searchType {
            titleSearchCoordinator.clearQuery()
        } else if .searchGeneral == searchType {
            generalSearchCoordinator.clearQuery()
        }
    }
    
    private func updateUI() {
        
        if searchType == .searchAuthor {
            authorSearchCoordinator.updateUI()
        } else if .searchTitle == searchType {
            titleSearchCoordinator.updateUI()
        } else if .searchGeneral == searchType {
            generalSearchCoordinator.updateUI()
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
    
    // MARK: Search View Controller
    
    func presentSearch() -> Void {
        
        performSegueWithIdentifier( "openBookSearch", sender: self )
    }
    
    @IBAction func dismiss(segue: UIStoryboardSegue) {
        
        if let vc = bookSearchVC {
            if !vc.searchKeys.isEmpty {
                
                searchType = .searchGeneral
                tableView.reloadData()
            }
        }
    }

    
}

