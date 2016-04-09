//
//  OLAuthorSearchViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit
import CoreData

import BNRCoreDataStack

class OLAuthorSearchViewController: UIViewController, UISearchResultsUpdating, UISearchBarDelegate {

    // MARK: Properties
    let operationQueue = OperationQueue()
    var coreDataStack: CoreDataStack?
    
    var searchResultsVC: OLAuthorSearchResultsTableViewController?
    var searchController = UISearchController( searchResultsController: nil )    

    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.scopeButtonTitles = ["Author", "Title" ]
        searchController.searchBar.delegate = self
        
        searchResultsVC?.tableView.tableHeaderView = searchController.searchBar
        
        searchController.searchBar.sizeToFit()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if "embedAuthorSearchResults" == segue.identifier {
            if let vc = segue.destinationViewController as? OLAuthorSearchResultsTableViewController {
     
                vc.queryCoordinator =
                    
                vc.operationQueue = self.operationQueue
                vc.coreDataStack = self.coreDataStack
                self.searchResultsVC = vc
//                vc.clearSearchResults()
            }
        }
    }
    
    // MARK: UISearchBarDelegate
    func searchBarSearchButtonClicked( searchBar: UISearchBar ) {
        
        if let sr = self.searchResultsVC, let text = searchBar.text {
            
            sr.getFirstSearchResults( text, scopeIndex: searchBar.selectedScopeButtonIndex )
            
        }
    }
    
    func searchBar( searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int ) {
        
        if let sr = self.searchResultsVC, let text = searchBar.text {
            
            sr.getFirstSearchResults( text, scopeIndex: searchBar.selectedScopeButtonIndex )
            
        }
    }
    
    func updateSearchResultsForSearchController( searchController: UISearchController ) {
        
        
    }
    
}

