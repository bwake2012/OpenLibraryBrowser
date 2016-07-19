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
    case searchGeneralExpanding = 3
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
    var searchType: SearchType = .searchGeneralExpanding
    var bookSearchVC: OLBookSearchViewController?
    
    var touchedCellIndexPath: NSIndexPath?
    
    var savedSearchKeys = [String: String]()

    @IBAction func presentGeneralSearch(sender: UIBarButtonItem) {}
    @IBAction func presentSearchResultsFilter(sender: UIBarButtonItem) {}
    
    // MARK: UIViewController
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.estimatedRowHeight = 68.0
//        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.tableFooterView = UIView(frame: .zero)

//        UIView.animateWithDuration(
//            0.3, delay: 0.0, options: .CurveLinear,
//            
//            animations: {
//                () -> Void in
//                self.tableView.beginUpdates()
//                self.tableView.endUpdates()
//            }
//        ) { (finished) -> Void in }
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
                    destVC.searchKeys = savedSearchKeys
                    
                    self.bookSearchVC = destVC
                    destVC.saveSearchDictionary = self.saveSearchKeys
                }
            }

        } else if segue.identifier == "displayGeneralSearchAuthorDetail" {

            if let indexPath = tableView.indexPathForSelectedRow {
                if let destVC = segue.destinationViewController as? OLAuthorDetailViewController {
                    
                    generalSearchCoordinator.installAuthorDetailCoordinator( destVC, indexPath: indexPath )
                }
            }

        } else if segue.identifier == "displayGeneralSearchWorkDetail" {
            
            if let indexPath = tableView.indexPathForSelectedRow {
                if let destVC = segue.destinationViewController as? OLWorkDetailViewController {
                    
                    generalSearchCoordinator.installWorkDetailCoordinator( destVC, indexPath: indexPath )
                }
            }
            
        } else if segue.identifier == "largeCoverImage" {

            if let indexPath = tableView.indexPathForSelectedRow {
                if let destVC = segue.destinationViewController as? OLPictureViewController {
                    
                    generalSearchCoordinator.installCoverPictureViewCoordinator( destVC, indexPath: indexPath )
                }
            }

        } else {

            if let indexPath = self.tableView.indexPathForSelectedRow {
                if segue.identifier == "displayAuthorDetail" {
                
                    if let destVC = segue.destinationViewController as? OLAuthorDetailViewController {
                        
                        if .searchAuthor == searchType {
                            searchController.active = false
                            authorSearchCoordinator.installAuthorDetailCoordinator( destVC, indexPath: indexPath )
                        } else if .searchGeneral == searchType || .searchGeneralExpanding == searchType {
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
    
    override func tableView( tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath ) -> CGFloat {
        
        var height = UITableViewAutomaticDimension
        if .searchGeneralExpanding == searchType {
            
            height =
                SegmentedTableViewCell.cellHeight(
                    indexPath,
                    withData: nil
                )
        }

        return height
    }
    
    override func tableView( tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath ) -> CGFloat {
        
        var height = UITableViewAutomaticDimension
        if .searchGeneralExpanding == searchType {

            height =
                SegmentedTableViewCell.cellHeight(
                        indexPath,
                        withData: generalSearchCoordinator.objectAtIndexPath( indexPath )
                    )
        }
        
        return height
    }

    override func tableView( tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        
        if .searchGeneralExpanding == searchType {
            
            let cell = tableView.cellForRowAtIndexPath( indexPath ) as! SegmentedTableViewCell
            
            let isOpen = cell.isOpen( indexPath )
            
            if isOpen {
                
                contractCell( tableView, segmentedCell: cell, indexPath: indexPath )
                
            }
            
            if !isOpen {

                expandCell( tableView, segmentedCell: cell, indexPath: indexPath )
            }
        }
    }

    override func tableView( tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath ) {
        
        if let cell = cell as? GeneralSearchResultSegmentedTableViewCell {
            
            cell.selectedAnimation( indexPath )
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if .searchGeneralExpanding == searchType {
            
            if let cell = tableView.cellForRowAtIndexPath( indexPath ) as? SegmentedTableViewCell {
            
                expandCell( tableView, segmentedCell: cell, indexPath: indexPath )

            } else {
                
                SegmentedTableViewCell.setOpen( indexPath )
            }
        }
    }
    
    override func tableView( tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath ) {
        
        if .searchGeneralExpanding == searchType {
            
            if let cell = tableView.cellForRowAtIndexPath( indexPath ) as? SegmentedTableViewCell {
            
                contractCell( tableView, segmentedCell: cell, indexPath: indexPath )
            
            } else {
                
                SegmentedTableViewCell.setClosed( indexPath )
            }
        }
    }
    
    // MARK: UITableviewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        if .searchAuthor == self.searchType {
            return authorSearchCoordinator.numberOfSections() ?? 1
        } else if .searchTitle == searchType {
            return titleSearchCoordinator.numberOfSections() ?? 1
        } else if .searchGeneral == searchType || .searchGeneralExpanding == searchType {
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

        } else if .searchGeneral == searchType || .searchGeneralExpanding == searchType {
            
            return generalSearchCoordinator.numberOfRowsInSection( section ) ?? 0
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell? = nil
        if .searchAuthor == searchType {

            let authorCell = tableView.dequeueReusableCellWithIdentifier( "authorSearchResult", forIndexPath: indexPath ) as! AuthorSearchResultTableViewCell
            
            authorSearchCoordinator.displayToCell( authorCell, indexPath: indexPath )
            
            cell = authorCell

        } else if .searchTitle == searchType {
            
            let titleCell = tableView.dequeueReusableCellWithIdentifier( "titleSearchResult", forIndexPath: indexPath ) as! TitleSearchResultTableViewCell
            
            titleSearchCoordinator.displayToCell( titleCell, indexPath: indexPath )
            
            cell = titleCell
            
        } else if .searchGeneral == searchType {
            
            let generalCell = tableView.dequeueReusableCellWithIdentifier( "generalSearchResult", forIndexPath: indexPath ) as! GeneralSearchResultTableViewCell
            
            generalSearchCoordinator.displayToCell( generalCell, indexPath: indexPath )
            
            cell = generalCell

        } else if .searchGeneralExpanding == searchType {
            
            if let expandingCell = tableView.dequeueReusableCellWithIdentifier( GeneralSearchResultSegmentedTableViewCell.nameOfClass ) as? GeneralSearchResultSegmentedTableViewCell {

                if let object = generalSearchCoordinator.objectAtIndexPath( indexPath ) {
                
                    expandingCell.configure( self, indexPath: indexPath, generalResult: object )
                    generalSearchCoordinator.updateUI( object, cell: expandingCell )
                }

                cell = expandingCell
            }
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
            
        } else if SearchType( rawValue: scopeIndex ) == .searchGeneral || .searchGeneralExpanding == searchType {
            
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
        } else if .searchGeneral == searchType || .searchGeneralExpanding == searchType {
            generalSearchCoordinator.clearQuery()
        }
    }
    
    private func updateUI() {
        
        if searchType == .searchAuthor {
            authorSearchCoordinator.updateUI()
        } else if .searchTitle == searchType {
            titleSearchCoordinator.updateUI()
        } else if .searchGeneral == searchType || .searchGeneralExpanding == searchType {
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
    
    // MARK: SaveSearchDictionary
    
    func saveSearchKeys( searchKeys: [String: String] ) -> Void {
        
        self.savedSearchKeys = searchKeys
    }
    
    // MARK: Search View Controller
    
    func presentSearch() -> Void {
        
        performSegueWithIdentifier( "openBookSearch", sender: self )
    }
    
    @IBAction func dismiss(segue: UIStoryboardSegue) {
        
        if segue.identifier == "beginBookSearch" {

            if let vc = segue.sourceViewController as? OLBookSearchViewController {

                if !vc.searchKeys.isEmpty {
                    
                    // searchType = .searchGeneral

                    SegmentedTableViewCell.purgeCellHeights()
                    generalSearchCoordinator.newQuery( vc.searchKeys, userInitiated: true, refreshControl: nil )
                    tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: cell expansion and contraction
    
    private func expandCell( tableView: UITableView, segmentedCell: SegmentedTableViewCell, indexPath: NSIndexPath ) {
        
//        if !SegmentedTableViewCell.animationInProgress() {
            
            let duration = 0.3
            
            segmentedCell.setOpen( indexPath )
            
            UIView.animateWithDuration(
                duration, delay: 0, options: .CurveLinear,
                animations: {
                    () -> Void in
                    tableView.beginUpdates()
                    tableView.endUpdates()
                }
            ) {
                (finished) -> Void in
                
                segmentedCell.selectedAnimation( indexPath, expandCell: true, animated: true ) {
                    
                    SegmentedTableViewCell.animationComplete()
                }
            }
//        }
    }
    
    private func contractCell( tableView: UITableView, segmentedCell: SegmentedTableViewCell, indexPath: NSIndexPath ) {
        
//        if !SegmentedTableViewCell.animationInProgress() {
            
            let duration = 0.1 // isOpen ? 0.3 : 0.1 // isOpen ? 1.1 : 0.6
            
            segmentedCell.selectedAnimation( indexPath, expandCell: false, animated: true ) {
                
                UIView.animateWithDuration(
                    duration, delay: 0.0, options: .CurveLinear,
                    
                    animations: {
                        () -> Void in
                        tableView.beginUpdates()
                        tableView.endUpdates()
                    }
                ) {
                    (finished) -> Void in
                    
                    SegmentedTableViewCell.animationComplete()
                }
            }
//        }
    }
}

extension OLSearchResultsTableViewController: ImageViewTransitionSource {
    
    func transitionSourceRectView() -> UIImageView? {
        
        if let indexPath = tableView.indexPathForSelectedRow {
            if let cell = tableView.cellForRowAtIndexPath( indexPath ) as? GeneralSearchResultSegmentedTableViewCell {
                
                return cell.transitionSourceRectView()
            }
        }
        
        return nil
    }
}

