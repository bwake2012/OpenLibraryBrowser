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

class OLAuthorSearchViewController: UIViewController, UISearchBarDelegate {

    // MARK: Properties
    let operationQueue = OperationQueue()
    
    var appCoreDataStack: CoreDataStack?
    var searchResultsVC: OLAuthorSearchResultsTableViewController?
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if "embedAuthorSearchResults" == segue.identifier {
            if let vc = segue.destinationViewController as? OLAuthorSearchResultsTableViewController {
                
                vc.operationQueue = self.operationQueue
                vc.coreDataStack = self.appCoreDataStack
                self.searchResultsVC = vc
//                vc.clearSearchResults()
            }
        }
    }
    
    // MARK: UISearchBarDelegate
    func searchBarSearchButtonClicked( searchBar: UISearchBar ) {
        
        if let sr = self.searchResultsVC, let text = searchBar.text {
            
            sr.getFirstAuthorSearchResults( text )
            
        }
    }
    
}

