//
//  OLSearchResultsTableViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit
import CoreData

class OLSearchResultsTableViewController: UIViewController {

    // MARK: Properties
    var sortButton: UIBarButtonItem?
    var searchButton: UIBarButtonItem?
    
    var generalSearchCoordinator: GeneralSearchResultsCoordinator?
    
    var searchController = UISearchController( searchResultsController: nil )
    
    var touchedCellIndexPath: NSIndexPath?
    
    var savedSearchKeys = [String: String]()
    var savedIndexPath: NSIndexPath?
    var savedAuthorKey: String?
    
    var beginningOffset: CGFloat = 0.0

    @IBAction func presentGeneralSearch(sender: UIBarButtonItem) {
        
        performSegueWithIdentifier( "openBookSearch", sender: sender )
    }
    @IBAction func presentSearchResultsSort(sender: UIBarButtonItem) {
        
        performSegueWithIdentifier( "openBookSort", sender: sender )
    }
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet private var refreshControl: UIRefreshControl?
    
    @IBOutlet private var activityView: UIActivityIndicatorView!
    
    deinit {
        
        SegmentedTableViewCell.emptyCellHeights( tableView )
        
        generalSearchCoordinator?.saveState()
    }
    
    // MARK: UIViewController
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        GeneralSearchResultSegmentedTableViewCell.registerCell( tableView )
        OLTableViewHeaderFooterView.registerCell( tableView )
        
        SegmentedTableViewCell.emptyCellHeights( tableView )
        
        // Do any additional setup after loading the view, typically from a nib.
        let sortImage   = UIImage(named: "rsw-sort-20x28")!
        let searchImage = UIImage(named: "708-search")!
        
        sortButton =
            UIBarButtonItem(
                    image: sortImage,
                    style: .Plain,
                    target: self,
                    action: #selector( OLSearchResultsTableViewController.presentSearchResultsSort( _: ) )
                )
        sortButton?.tintColor = UIColor.whiteColor()
        
        searchButton =
            UIBarButtonItem(
                    image: searchImage,
                    style: .Plain,
                    target: self,
                    action: #selector(OLSearchResultsTableViewController.presentGeneralSearch( _: ) )
                )
        searchButton?.tintColor = UIColor.whiteColor()
        
        navigationItem.rightBarButtonItems = [searchButton!, sortButton!]
        navigationItem.leftBarButtonItem?.tintColor = UIColor.whiteColor()
        
        self.tableView.estimatedRowHeight = SegmentedTableViewCell.estimatedCellHeight
//        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        if let tableFooterView = OLTableViewHeaderFooterView.createFromNib() as? OLTableViewHeaderFooterView {

            self.tableView.tableFooterView = tableFooterView
            tableFooterView.footerLabel.text = "Tap the Search Button to Look for Books"
        }
        
        generalSearchCoordinator = buildQueryCoordinator()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        // navigationController?.hidesBarsOnSwipe = true

        if let indexPath = savedIndexPath {
            
            tableView.selectRowAtIndexPath( indexPath, animated: true, scrollPosition: .None )
            savedIndexPath = nil
        
        }
    }
    
    override func didReceiveMemoryWarning() {

        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        generalSearchCoordinator?.saveState()
    }
    
    override func viewDidLayoutSubviews() {

        super.viewDidLayoutSubviews()
        
        // Dynamic sizing for the header view
        if let footerView = tableView.tableFooterView {
            let height = footerView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            var footerFrame = footerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get
            // repeatedly, causing the app to hang.
            if height != footerFrame.size.height {
                footerFrame.size.height = height
                footerView.frame = footerFrame
                tableView.tableFooterView = footerView
            }
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
       
        super.viewWillTransitionToSize( size, withTransitionCoordinator: coordinator )

        SegmentedTableViewCell.emptyCellHeights( tableView )
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        
        super.traitCollectionDidChange( previousTraitCollection )
        
        guard let visible = tableView.indexPathsForVisibleRows else { return }
            
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        
        guard visible.contains( indexPath ) else { return }
        
        guard let cell = tableView.cellForRowAtIndexPath( indexPath ) as? SegmentedTableViewCell else { return }
        
        guard !cell.key.isEmpty else { return }

        expandCell( tableView, segmentedCell: cell, key: cell.key )
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        guard let generalSearchCoordinator = generalSearchCoordinator else {
            assert( false )
            return
        }
        
        guard let segueName = segue.identifier else { assert( false ); return }
        
        if segueName == "openBookSearch" {
            
            if let destVC = segue.destinationViewController as? OLBookSearchViewController {

                destVC.initialSearchKeys( generalSearchCoordinator.searchKeys )
                    
                destVC.saveSearchDictionary = saveSearchKeys
            }
        } else if segueName == "openBookSort" {
            
            if let destVC = segue.destinationViewController as? OLBookSortViewController {

                destVC.sortFields = generalSearchCoordinator.sortFields
                    
                destVC.saveSortFields = self.saveSortFields
            }
            
        } else if let indexPath = tableView.indexPathForSelectedRow {
        
            savedIndexPath = indexPath
            
            switch segueName {
            
            case "displayGeneralSearchAuthorDetail":

                if let destVC = segue.destinationViewController as? OLAuthorDetailViewController {
                    
                    if let key = savedAuthorKey {
                        
                        generalSearchCoordinator.installAuthorDetailCoordinator( destVC, authorKey: key )
                        savedAuthorKey = nil
                        
                    } else {

                        generalSearchCoordinator.installAuthorDetailCoordinator( destVC, indexPath: indexPath )
                    }
                }
                
            case "displayGeneralSearchAuthorList":
                
                if let destVC = segue.destinationViewController as? OLAuthorsTableViewController {
                    
                    generalSearchCoordinator.installAuthorsTableViewCoordinator( destVC, indexPath: indexPath )
                    destVC.saveAuthorKey = self.saveAuthorKey
                }

            case "displayGeneralSearchWorkDetail":
                
                if let destVC = segue.destinationViewController as? OLWorkDetailViewController {
                    
                    generalSearchCoordinator.installWorkDetailCoordinator( destVC, indexPath: indexPath )
                }
                
            case "largeCoverImage":

                if let destVC = segue.destinationViewController as? OLPictureViewController {
                    
                    generalSearchCoordinator.installCoverPictureViewCoordinator( destVC, indexPath: indexPath )
                }
 
            case "displayWorkEBooks":

                if let destVC = segue.destinationViewController as? OLWorkDetailViewController {
                    
                    generalSearchCoordinator.installWorkDetailCoordinator( destVC, indexPath: indexPath )
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
            
            savedIndexPath = nil
            tableView.reloadData()
        }
    }
    
    // MARK: Authors Table View Controller
    
    func presentAuthors() -> Void {
        
        performSegueWithIdentifier( "displayGeneralSearchAuthorList", sender: self )
    }
    
    func saveAuthorKey( authorKey: String ) -> Void {
        
        savedAuthorKey = authorKey
    }
    
    @IBAction func dismissAuthors(segue: UIStoryboardSegue) {
        
        if segue.identifier == "beginAuthorDetail" {
            
            if nil != savedAuthorKey {
                
                dispatch_async( dispatch_get_main_queue() ) {
                    
                    self.performSegueWithIdentifier( "displayGeneralSearchAuthorDetail", sender: self )
                }
            }
        }
    }
    
    // MARK: query in progress

    func coordinatorIsBusy() -> Void {
        
        activityView?.startAnimating()
        sortButton?.enabled = false
        searchButton?.enabled = false
        
        SegmentedTableViewCell.emptyIndexPathToKeyLookup( tableView )
    }
    
    func coordinatorIsNoLongerBusy() -> Void {
        
        activityView?.stopAnimating()
        sortButton?.enabled = true
        searchButton?.enabled = true
    }
    
    // MARK: cell expansion and contraction
    
    private func expandCell( tableView: UITableView, segmentedCell: SegmentedTableViewCell, key: String ) {

        let duration = 0.3
        
        segmentedCell.setOpen( tableView, key: key )
        
        UIView.animateWithDuration(
            duration, delay: 0, options: .CurveLinear,
            animations: {
                () -> Void in
                
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        ) {
            (finished) -> Void in
            
            segmentedCell.selectedAnimation( tableView, key: key, expandCell: true, animated: true ) {
                
                SegmentedTableViewCell.animationComplete()
            }
        }
    }
    
    private func contractCell( tableView: UITableView, segmentedCell: SegmentedTableViewCell, key: String ) {
        
        let duration = 0.1 // isOpen ? 0.3 : 0.1 // isOpen ? 1.1 : 0.6
        
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

// MARK: UIScrollViewDelegate

extension OLSearchResultsTableViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging( scrollView: UIScrollView, willDecelerate decelerate: Bool ) {
        
        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Change 10.0 to adjust the distance from bottom
        if maximumOffset - currentOffset <= -10.0 {
            
            generalSearchCoordinator?.nextQueryPage()
        
        } else if currentOffset <= -10.0 {
            
            navigationController?.setNavigationBarHidden( false, animated: true )
        }
        
    }

    func scrollViewWillEndDragging( scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint> ) {
        
        // up
        if velocity.y < -1.5 {
            navigationController?.setNavigationBarHidden( false, animated: true )
        }
    }
}

// MARK: UITableViewDelegate

extension OLSearchResultsTableViewController: UITableViewDelegate {
    
    // do not implement this function! The overhead involved in getting the key isn't worth it

    func tableView( tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath ) -> CGFloat {
        
        let height = SegmentedTableViewCell.estimatedCellHeight
        
//        print( "estimatedHeightForRowAtIndexPath \(indexPath.row) \(height)" )
        return height
    }
    
    func tableView( tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath ) -> CGFloat {
        
        assert( NSThread.isMainThread() )

        var height = SegmentedTableViewCell.estimatedCellHeight

        let cell = tableView.cellForRowAtIndexPath( indexPath ) as? SegmentedTableViewCell
        if let cell = cell {

            height = cell.height( tableView )

        } else {
            
            height = SegmentedTableViewCell.cachedHeightForRowAtIndexPath( tableView, indexPath: indexPath )
        }

//        print( "heightForRowAtIndexPath: \(cell?.key ?? "nil") \(indexPath.row) \(height)" )
        
        return height
    }

    func tableView( tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath ) {
        
        if let cell = cell as? GeneralSearchResultSegmentedTableViewCell {
            
            cell.selectedAnimation( tableView, key: cell.key )

//            print( "willDisplayCell forRowAtIndexPath \(indexPath.row) \(cell.key)" )
        }
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let cell = tableView.cellForRowAtIndexPath( indexPath ) as? SegmentedTableViewCell {
        
            generalSearchCoordinator?.didSelectRowAtIndexPath( indexPath )

            expandCell( tableView, segmentedCell: cell, key: cell.key )
            
//            tableView.scrollToNearestSelectedRowAtScrollPosition( .Top, animated: true )

//            print( "didSelectRowAtIndexPath \(indexPath.row) \(cell.key)" )

        }
    }
    
    func tableView( tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath ) {
        
        SegmentedTableViewCell.setClosed( tableView, indexPath: indexPath )
        if let cell = tableView.cellForRowAtIndexPath( indexPath ) as? SegmentedTableViewCell {
            
            contractCell( tableView, segmentedCell: cell, key: cell.key )
            
//            print( "didDeselectRowAtIndexPath \(indexPath.row) \(cell.key)" )
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
                
                expandingCell.tableVC = self
                expandingCell.configure( tableView, indexPath: indexPath, key: object.key, data: object )
                generalSearchCoordinator?.displayThumbnail( object, cell: expandingCell )
            }
            
//            print( "cellForRowAtIndexPath \(indexPath.row) \(expandingCell.key)" )
        
            cell = expandingCell
        }
        
        return cell!
    }
    
}

