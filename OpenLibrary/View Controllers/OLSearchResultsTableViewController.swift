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

class OLSearchResultsTableViewController: UIViewController {

    // MARK: Properties
    var generalSearchCoordinator: GeneralSearchResultsCoordinator?
    
    var searchController = UISearchController( searchResultsController: nil )
    
    var touchedCellIndexPath: NSIndexPath?
    
    var savedSearchKeys = [String: String]()
    var savedIndexPath: NSIndexPath?

    @IBAction func presentGeneralSearch(sender: UIBarButtonItem) {}
    @IBAction func presentSearchResultsSort(sender: UIBarButtonItem) {}
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet private var refreshControl: UIRefreshControl?
    
    @IBOutlet private var activityView: UIActivityIndicatorView!
    @IBOutlet private var searchButton: UIButton!
    @IBOutlet private var sortButton:   UIButton!
    
    deinit {
        
        SegmentedTableViewCell.purgeCellHeights( tableView )
        
        generalSearchCoordinator?.saveState()
    }
    
    // MARK: UIViewController
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
//        GeneralSearchResultSegmentedTableViewCell.registerCell( tableView )
        OLTableViewHeaderFooterView.registerCell( tableView )
        
        SegmentedTableViewCell.emptyCellHeights( tableView )
        
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.estimatedRowHeight = 68.0
//        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.tableFooterView = OLTableViewHeaderFooterView.createFromNib()

        generalSearchCoordinator = buildQueryCoordinator()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear( animated )
        
        if let indexPath = savedIndexPath {
            
            tableView.selectRowAtIndexPath( indexPath, animated: animated, scrollPosition: .Top )
            savedIndexPath = nil
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if let indexPath = tableView.indexPathForSelectedRow {

            tableView( tableView, didSelectRowAtIndexPath: indexPath )
        }
    }
    
    override func didReceiveMemoryWarning() {

        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        generalSearchCoordinator?.saveState()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        guard let generalSearchCoordinator = generalSearchCoordinator else {
            assert( false )
            return
        }
        
        guard let segueName = segue.identifier else { assert( false ); return }
        
        if segueName == "openBookSearch" {
            
            if let destVC = segue.destinationViewController as? OLBookSearchViewController {
                if let delegate = segue as? UIViewControllerTransitioningDelegate {
                    
                    destVC.transitioningDelegate = delegate
                    destVC.displaySearchKeys( generalSearchCoordinator.searchKeys )
                    
                    destVC.saveSearchDictionary = saveSearchKeys
                }
            }
        } else if segueName == "openBookSort" {
            
            if let destVC = segue.destinationViewController as? OLBookSortViewController {
                if let delegate = segue as? UIViewControllerTransitioningDelegate {
                    
                    destVC.transitioningDelegate = delegate
                    destVC.sortFields = generalSearchCoordinator.sortFields
                    
                    destVC.saveSortFields = self.saveSortFields
                }
            }
            
        } else if let indexPath = tableView.indexPathForSelectedRow {
        
            savedIndexPath = indexPath
            
            switch segueName {
            
            case "displayGeneralSearchAuthorDetail":

                if let destVC = segue.destinationViewController as? OLAuthorDetailViewController {
                    
                    generalSearchCoordinator.installAuthorDetailCoordinator( destVC, indexPath: indexPath )
                }

            case "displayGeneralSearchWorkDetail":
                
                if let destVC = segue.destinationViewController as? OLWorkDetailViewController {
                    
                    generalSearchCoordinator.installWorkDetailCoordinator( destVC, indexPath: indexPath )
                }
                
            case "largeCoverImage":

                if let destVC = segue.destinationViewController as? OLPictureViewController {
                    
                    generalSearchCoordinator.installCoverPictureViewCoordinator( destVC, indexPath: indexPath )
                }
 
            case "displayEBookTableView":

                if let destVC = segue.destinationViewController as? OLEBookEditionsTableViewController {
                    
                    generalSearchCoordinator.installEBookEditionsCoordinator( destVC, indexPath: indexPath )
                }
                
            case "displayAuthorDetail":
                
                if let destVC = segue.destinationViewController as? OLAuthorDetailViewController {
                    
                    generalSearchCoordinator.installAuthorDetailCoordinator( destVC, indexPath: indexPath )
                }

            default:

                assert( false )
            }
        }
    }
    
    // MARK: Utility
    
    func buildQueryCoordinator() -> GeneralSearchResultsCoordinator {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

        return appDelegate.getGeneralSearchCoordinator( self )
    }
    
   // MARK: Search
    
    func getFirstSearchResults( authorName: String, scopeIndex: Int, userInitiated: Bool = true ) {

        self.title = "Search"
        
        tableView.reloadData()
    }
    
    func clearSearchResults() {
        
        generalSearchCoordinator?.clearQuery()
    }
    
    private func updateUI() {
        
        generalSearchCoordinator?.updateUI()
    }
    
    // MARK: Search View Controller
    
    func presentSearch() -> Void {
        
        performSegueWithIdentifier( "openBookSearch", sender: self )
    }
    
    func saveSearchKeys( searchKeys: [String: String] ) -> Void {
        
        self.savedSearchKeys = searchKeys
    }
    
    @IBAction func dismissSearch( segue: UIStoryboardSegue ) {

        if segue.identifier == "beginBookSearch" {
        
            if !savedSearchKeys.isEmpty {
                
                // searchType = .searchGeneral
                
                SegmentedTableViewCell.emptyCellHeights( tableView )
                generalSearchCoordinator?.newQuery( savedSearchKeys, userInitiated: true, refreshControl: nil )
                
                let indexPath = NSIndexPath( forRow: Foundation.NSNotFound, inSection: 0 )
                tableView.scrollToRowAtIndexPath( indexPath, atScrollPosition: .Top, animated: true )
            }
            savedIndexPath = nil
        }
    }
    
    // MARK: Sort View Controller
    
    func presentSort() -> Void {
        
        performSegueWithIdentifier( "openBookSort", sender: self )
    }
    
    func saveSortFields( sortFields: [SortField] ) -> Void {
        
        generalSearchCoordinator?.sortFields = sortFields
    }
    
    @IBAction func dismissSort(segue: UIStoryboardSegue) {
        
        if segue.identifier == "beginBookSort" {
            
            SegmentedTableViewCell.emptyCellHeights( tableView )
            savedIndexPath = nil
            tableView.reloadData()
        }
    }
    
    // MARK: query in progress

    func coordinatorIsBusy() -> Void {
        
        activityView?.startAnimating()
        searchButton.enabled = false
        sortButton.enabled = false
    }
    
    func coordinatorIsNoLongerBusy() -> Void {
        
        activityView?.stopAnimating()
        searchButton.enabled = true
        sortButton.enabled = true
    }
    
    // MARK: cell expansion and contraction
    
    private func expandCell( tableView: UITableView, segmentedCell: SegmentedTableViewCell, indexPath: NSIndexPath ) {
        
//        if !SegmentedTableViewCell.animationInProgress() {
            
            let duration = 0.3
            
            segmentedCell.setOpen( tableView, indexPath: indexPath )
            
            UIView.animateWithDuration(
                duration, delay: 0, options: .CurveLinear,
                animations: {
                    () -> Void in
                    tableView.beginUpdates()
                    tableView.endUpdates()
                }
            ) {
                (finished) -> Void in
                
                segmentedCell.selectedAnimation( tableView, indexPath: indexPath, expandCell: true, animated: true ) {
                    
                    SegmentedTableViewCell.animationComplete()
                }
            }
//        }
    }
    
    private func contractCell( tableView: UITableView, segmentedCell: SegmentedTableViewCell, indexPath: NSIndexPath ) {
        
//        if !SegmentedTableViewCell.animationInProgress() {
            
            let duration = 0.1 // isOpen ? 0.3 : 0.1 // isOpen ? 1.1 : 0.6
            
            segmentedCell.adjustCellHeights( tableView, indexPath: indexPath )
        
            segmentedCell.selectedAnimation( tableView, indexPath: indexPath, expandCell: false, animated: true ) {
                
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

extension OLSearchResultsTableViewController: TransitionSourceImage {
    
    func transitionSourceRectImageView() -> UIImageView? {
        
        if let indexPath = tableView.indexPathForSelectedRow {
            if let cell = tableView.cellForRowAtIndexPath( indexPath ) as? GeneralSearchResultSegmentedTableViewCell {
                
                return cell.transitionSourceRectView()
            }
        }
        
        return nil
    }
}

extension OLSearchResultsTableViewController: TransitionSourceCell {
    
    func transitionSourceRectCellView() -> UITableViewCell? {
        
        var sourceRectView: UITableViewCell?
        
        if let indexPath = tableView.indexPathForSelectedRow {
            
            sourceRectView = tableView.cellForRowAtIndexPath( indexPath )
        }
        
        return sourceRectView
    }
        
}

extension OLSearchResultsTableViewController: UITableViewDelegate {
    
    // MARK: UITableViewDelegate
    
    func tableView( tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath ) -> CGFloat {
        
        var height = UITableViewAutomaticDimension
        
        height = GeneralSearchResultSegmentedTableViewCell.estimatedCellHeight( tableView, indexPath: indexPath )
        
        return height
    }
    
    func tableView( tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath ) -> CGFloat {
        
        var height = UITableViewAutomaticDimension

        height =
            GeneralSearchResultSegmentedTableViewCell.cellHeight(
                    tableView,
                    indexPath: indexPath,
                    withData: generalSearchCoordinator?.objectAtIndexPath( indexPath )
                )
        
        return height
    }
    
    //    func tableView( tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
    //
    //        if .searchGeneralExpanding == searchType {
    //
    //            let cell = tableView.cellForRowAtIndexPath( indexPath ) as! SegmentedTableViewCell
    //
    //            let isOpen = cell.isOpen( tableView, indexPath: indexPath )
    //
    //            if isOpen {
    //
    //                contractCell( tableView, segmentedCell: cell, indexPath: indexPath )
    //
    //            }
    //
    //            if !isOpen {
    //
    //                expandCell( tableView, segmentedCell: cell, indexPath: indexPath )
    //            }
    //        }
    //    }
    
    func tableView( tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath ) {
        
        if let cell = cell as? GeneralSearchResultSegmentedTableViewCell {
            
            cell.adjustCellHeights( tableView, indexPath: indexPath )
            
            cell.selectedAnimation( tableView, indexPath: indexPath )
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let cell = tableView.cellForRowAtIndexPath( indexPath ) as? SegmentedTableViewCell {
            
            expandCell( tableView, segmentedCell: cell, indexPath: indexPath )
            
            tableView.scrollToNearestSelectedRowAtScrollPosition( .Top, animated: true )
            
        } else {
            
            SegmentedTableViewCell.setOpen( tableView, indexPath: indexPath )
        }
    }
    
    func tableView( tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath ) {
        
        if let cell = tableView.cellForRowAtIndexPath( indexPath ) as? SegmentedTableViewCell {
            
            contractCell( tableView, segmentedCell: cell, indexPath: indexPath )
            
        } else {
            
            SegmentedTableViewCell.setClosed( tableView, indexPath: indexPath )
        }
    }
    
}

extension OLSearchResultsTableViewController: UITableViewDataSource {
    
    // MARK: UITableviewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        guard let generalSearchCoordinator = generalSearchCoordinator else {
            return 0
        }
        
        return generalSearchCoordinator.numberOfSections()
    }
    
    func tableView( tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        guard let generalSearchCoordinator = generalSearchCoordinator else {
            return 0
        }
        
        return generalSearchCoordinator.numberOfRowsInSection( section )
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell? = nil
        
        if let expandingCell = tableView.dequeueReusableCellWithIdentifier( GeneralSearchResultSegmentedTableViewCell.nameOfClass ) as? GeneralSearchResultSegmentedTableViewCell {
            
            if let object = generalSearchCoordinator?.objectAtIndexPath( indexPath ) {
                
                expandingCell.configure( tableView, indexPath: indexPath, data: object )
                generalSearchCoordinator?.updateUI( object, cell: expandingCell )
            }
            
            cell = expandingCell
        }
        
        return cell!
    }
    
}

