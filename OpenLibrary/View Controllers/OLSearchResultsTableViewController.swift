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
        self.tableView.estimatedRowHeight = SegmentedTableViewCell.estimatedCellHeight
//        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.tableFooterView = OLTableViewHeaderFooterView.createFromNib()

        generalSearchCoordinator = buildQueryCoordinator()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        navigationController?.hidesBarsOnSwipe = true

        if let indexPath = savedIndexPath {
            
            tableView.selectRowAtIndexPath( indexPath, animated: true, scrollPosition: .Top )
            savedIndexPath = nil
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
//                if let delegate = segue as? UIViewControllerTransitioningDelegate {
                    
//                    destVC.transitioningDelegate = delegate
                    destVC.initialSearchKeys( generalSearchCoordinator.searchKeys )
                    
                    destVC.saveSearchDictionary = saveSearchKeys
//                }
            }
        } else if segueName == "openBookSort" {
            
            if let destVC = segue.destinationViewController as? OLBookSortViewController {
//                if let delegate = segue as? UIViewControllerTransitioningDelegate {
                    
//                    destVC.transitioningDelegate = delegate
                    destVC.sortFields = generalSearchCoordinator.sortFields
                    
                    destVC.saveSortFields = self.saveSortFields
//                }
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
    
    // MARK: UIScrollViewController
    
    func scrollViewDidEndDragging( scrollView: UIScrollView, willDecelerate decelerate: Bool ) {
        
        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Change 10.0 to adjust the distance from bottom
        if maximumOffset - currentOffset <= 10.0 {
            
            generalSearchCoordinator?.nextQueryPage()
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
            
//            SegmentedTableViewCell.emptyCellHeights( tableView )
            savedIndexPath = nil
            tableView.reloadData()
        }
    }
    
    // MARK: query in progress

    func coordinatorIsBusy() -> Void {
        
        activityView?.startAnimating()
        self.navigationItem.leftBarButtonItem?.enabled = false
        self.navigationItem.rightBarButtonItem?.enabled = false
    }
    
    func coordinatorIsNoLongerBusy() -> Void {
        
        activityView?.stopAnimating()
        self.navigationItem.leftBarButtonItem?.enabled = true
        self.navigationItem.rightBarButtonItem?.enabled = true
    }
    
    // MARK: cell expansion and contraction
    
    private func expandCell( tableView: UITableView, segmentedCell: SegmentedTableViewCell, key: String ) {

            let duration = 0.3
            
            segmentedCell.setOpen( tableView, key: key )
        
//            if let visibleRows = tableView.indexPathsForVisibleRows {
            
                UIView.animateWithDuration(
                    duration, delay: 0, options: .CurveLinear,
                    animations: {
                        () -> Void in
                        
//                        tableView.reloadRowsAtIndexPaths( visibleRows, withRowAnimation: .Automatic )
                        tableView.beginUpdates()
                        tableView.endUpdates()
                    }
                ) {
                    (finished) -> Void in
                    
                    segmentedCell.selectedAnimation( tableView, key: key, expandCell: true, animated: true ) {
                        
                        SegmentedTableViewCell.animationComplete()
                    }
                }
//            }
        
    }
    
    private func contractCell( tableView: UITableView, segmentedCell: SegmentedTableViewCell, key: String ) {
        
//        if !SegmentedTableViewCell.animationInProgress() {
            
            let duration = 0.1 // isOpen ? 0.3 : 0.1 // isOpen ? 1.1 : 0.6
            
            segmentedCell.adjustCellHeights( tableView, key: key )
        
            segmentedCell.selectedAnimation( tableView, key: key, expandCell: false, animated: true ) {
                
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

// MARK: UITableViewDelegate

extension OLSearchResultsTableViewController: UITableViewDelegate {
    
    // do not implement this function! The overhead involved in getting the key isn't worth it

    func tableView( tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath ) -> CGFloat {
        
        let height = SegmentedTableViewCell.estimatedCellHeight
        
//        if let object = generalSearchCoordinator?.objectAtIndexPath( indexPath ) {
//        
//            height = GeneralSearchResultSegmentedTableViewCell.estimatedCellHeight( tableView, key: object.key )
//        }
        
        return height
    }
    
    func tableView( tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath ) -> CGFloat {
        
        var height = SegmentedTableViewCell.estimatedCellHeight

        if let object = generalSearchCoordinator?.objectAtIndexPath( indexPath ) {
            height =
                GeneralSearchResultSegmentedTableViewCell.cellHeight(
                        tableView,
                        key: object.key,
                        withData: object
                    )
        }

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
        
        if let cell = cell as? GeneralSearchResultSegmentedTableViewCell,
               object = generalSearchCoordinator?.objectAtIndexPath( indexPath ) {
            
            cell.adjustCellHeights( tableView, key: object.key )
            
            cell.selectedAnimation( tableView, key: object.key )
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let object = generalSearchCoordinator?.objectAtIndexPath( indexPath ) {

            if let cell = tableView.cellForRowAtIndexPath( indexPath ) as? SegmentedTableViewCell {
            
                expandCell( tableView, segmentedCell: cell, key: object.key )
                
                tableView.scrollToNearestSelectedRowAtScrollPosition( .Top, animated: true )
                
            } else {
                
                SegmentedTableViewCell.setOpen( tableView, key: object.key )
            }
        }
    }
    
    func tableView( tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath ) {
        
        if let object = generalSearchCoordinator?.objectAtIndexPath( indexPath ) {
            
            if let cell = tableView.cellForRowAtIndexPath( indexPath ) as? SegmentedTableViewCell {
                
                contractCell( tableView, segmentedCell: cell, key: object.key )
                
            } else {
                
                SegmentedTableViewCell.setClosed( tableView, key: object.key )
            }
        }
    }
    
}

// MARK: UITableviewDataSource

extension OLSearchResultsTableViewController: UITableViewDataSource {
    
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
                
                expandingCell.configure( tableView, key: object.key, data: object )
                generalSearchCoordinator?.updateUI( object, cell: expandingCell )
            }
            
            cell = expandingCell
        }
        
        return cell!
    }
    
}

