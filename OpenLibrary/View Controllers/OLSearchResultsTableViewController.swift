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
    
    lazy var generalSearchCoordinator: GeneralSearchResultsCoordinator = self.buildQueryCoordinator()
    
    var searchController = UISearchController( searchResultsController: nil )
    
    var touchedCellIndexPath: IndexPath?
    
    var savedSearchKeys = [String: String]()
    var savedIndexPath: IndexPath?
    var savedAuthorKey: String?
    var immediateSegueName: String?
    var indexPathSavedForTransition: IndexPath?
        
    var beginningOffset: CGFloat = 0.0

    @IBAction func presentGeneralSearch(_ sender: UIBarButtonItem) {
        
        performSegue( withIdentifier: "openBookSearch", sender: sender )
    }
    @IBAction func presentSearchResultsSort(_ sender: UIBarButtonItem) {
        
        performSegue( withIdentifier: "openBookSort", sender: sender )
    }
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet fileprivate var refreshControl: UIRefreshControl?
    
    @IBOutlet fileprivate var activityView: UIActivityIndicatorView!
    
    deinit {
        
        SegmentedTableViewCell.emptyCellHeights( tableView )
        
        generalSearchCoordinator.saveState()
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
                    style: .plain,
                    target: self,
                    action: #selector( OLSearchResultsTableViewController.presentSearchResultsSort( _: ) )
                )
        sortButton?.tintColor = UIColor.white
        
        searchButton =
            UIBarButtonItem(
                    image: searchImage,
                    style: .plain,
                    target: self,
                    action: #selector(OLSearchResultsTableViewController.presentGeneralSearch( _: ) )
                )
        searchButton?.tintColor = UIColor.white
        
        navigationItem.rightBarButtonItems = [searchButton!, sortButton!]
        navigationItem.leftBarButtonItem?.tintColor = UIColor.white
        
        self.tableView.estimatedRowHeight = SegmentedTableViewCell.estimatedCellHeight
//        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        if let tableFooterView = OLTableViewHeaderFooterView.createFromNib() as? OLTableViewHeaderFooterView {

            self.tableView.tableFooterView = tableFooterView
            tableFooterView.footerLabel.text = NSLocalizedString( "Tap the Search Button to Look for Books", comment: "" )
        }
        
//        generalSearchCoordinator = buildQueryCoordinator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear( animated )
        
        generalSearchCoordinator.updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // navigationController?.hidesBarsOnSwipe = true
        
        if let indexPath = savedIndexPath {
            
            tableView.selectRow( at: indexPath, animated: true, scrollPosition: .none )
            savedIndexPath = nil
        }

        if let segueName = immediateSegueName {
            
            performSegue( withIdentifier: segueName, sender: self )
            immediateSegueName = nil
        }
    }
    
    override func didReceiveMemoryWarning() {

        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        generalSearchCoordinator.saveState()
    }
    
    override func viewDidLayoutSubviews() {

        super.viewDidLayoutSubviews()
        
        // Dynamic sizing for the header view
        if let footerView = tableView.tableFooterView {
            let height = footerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
       
        super.viewWillTransition( to: size, with: coordinator )

        SegmentedTableViewCell.emptyCellHeights( tableView )
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        super.traitCollectionDidChange( previousTraitCollection )
        
        guard let visible = tableView.indexPathsForVisibleRows else { return }
            
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        
        guard visible.contains( indexPath ) else { return }
        
        guard let cell = tableView.cellForRow( at: indexPath ) as? SegmentedTableViewCell else { return }
        
        guard !cell.key.isEmpty else { return }

        expandCell( tableView, segmentedCell: cell, key: cell.key )
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let segueName = segue.identifier else { assert( false ); return }
        
        if segueName == "openBookSearch" {
            
            if let destVC = segue.destination as? OLBookSearchViewController {

                destVC.initialSearchKeys( generalSearchCoordinator.searchKeys )
                    
                destVC.saveSearchDictionary = saveSearchKeys
            }
        } else if segueName == "openBookSort" {
            
            if let destVC = segue.destination as? OLBookSortViewController {

                destVC.sortFields = generalSearchCoordinator.sortFields
                    
                destVC.saveSortFields = self.saveSortFields
            }
            
        } else if let indexPath = tableView.indexPathForSelectedRow {
        
            savedIndexPath = indexPath
            indexPathSavedForTransition = indexPath
            
            switch segueName {
            
            case "displayGeneralSearchAuthorDetail":

                var destVC: OLAuthorDetailViewController?

                destVC = segue.destination as? OLAuthorDetailViewController
                if nil == destVC {
                    
                    if let navVC = segue.destination as? UINavigationController {
                        
                        destVC = navVC.topViewController as? OLAuthorDetailViewController
                    }
                }

                if let destVC = destVC {
                    
                    if let key = savedAuthorKey {
                        
                        generalSearchCoordinator.installAuthorDetailCoordinator( destVC, authorKey: key )
                        savedAuthorKey = nil
                        
                    } else {

                        generalSearchCoordinator.installAuthorDetailCoordinator( destVC, indexPath: indexPath )
                    }
                }
                
            case "displayGeneralSearchAuthorList":
                
                if let destVC = segue.destination as? OLAuthorsTableViewController {
                    
                    generalSearchCoordinator.installAuthorsTableViewCoordinator( destVC, indexPath: indexPath )
                    destVC.saveAuthorKey = self.saveAuthorKey
                }

            case "displayGeneralSearchWorkDetail":
                
                var destVC: OLWorkDetailViewController?
                
                destVC = segue.destination as? OLWorkDetailViewController
                if nil == destVC {
                    
                    if let navVC = segue.destination as? UINavigationController {
                        
                        destVC = navVC.topViewController as? OLWorkDetailViewController
                    }
                }
                
                if let destVC = destVC {
                    
                    if let delegate = splitViewController?.delegate as? SplitViewControllerDelegate {
                        
                        delegate.collapseDetailViewController = false
                    }
                    
                    generalSearchCoordinator.installWorkDetailCoordinator( destVC, indexPath: indexPath )
                }
                
            case "zoomLargeImage":

                var destVC: OLPictureViewController?
                
                destVC = segue.destination as? OLPictureViewController
                if nil == destVC {
                    
                    if let navVC = segue.destination as? UINavigationController {
                        
                        destVC = navVC.topViewController as? OLPictureViewController
                    }
                }
                
                if let destVC = destVC {
                    
                    generalSearchCoordinator.installCoverPictureViewCoordinator( destVC, indexPath: indexPath )
                }
 
            case "displayWorkEBooks":

                var destVC: OLWorkDetailViewController?
                
                destVC = segue.destination as? OLWorkDetailViewController
                if nil == destVC {
                    
                    if let navVC = segue.destination as? UINavigationController {
                        
                        destVC = navVC.topViewController as? OLWorkDetailViewController
                    }
                }
                
                if let destVC = destVC {
                    
                    generalSearchCoordinator.installWorkDetailCoordinator( destVC, indexPath: indexPath )
                }
                
            case "displayAuthorDetail":
                
                var destVC: OLAuthorDetailViewController?
                
                destVC = segue.destination as? OLAuthorDetailViewController
                if nil == destVC {
                    
                    if let navVC = segue.destination as? UINavigationController {
                        
                        destVC = navVC.topViewController as? OLAuthorDetailViewController
                    }
                }
                
                if let destVC = destVC {
                    
                    generalSearchCoordinator.installAuthorDetailCoordinator( destVC, indexPath: indexPath )
                }

            case "displayBlank":
                break
                
            default:

                assert( false )
            }
        }
    }
    
    // MARK: Utility
    
    func buildQueryCoordinator() -> GeneralSearchResultsCoordinator {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        return appDelegate.getGeneralSearchCoordinator( self )
    }
    
   // MARK: Search
    
    func getFirstSearchResults( _ authorName: String, scopeIndex: Int, userInitiated: Bool = true ) {

        self.title = "Search"
        
        tableView.reloadData()
    }
    
    func clearSearchResults() {
        
        generalSearchCoordinator.clearQuery()
    }
    
    fileprivate func updateUI() {
        
        generalSearchCoordinator.updateUI()
    }
    
    // MARK: Search View Controller
    
    func presentSearch() -> Void {
        
        performSegue( withIdentifier: "openBookSearch", sender: self )
    }
    
    func saveSearchKeys( _ searchKeys: [String: String] ) -> Void {
        
        self.savedSearchKeys = searchKeys
    }
    
    @IBAction func dismissSearch( _ segue: UIStoryboardSegue ) {

        if segue.identifier == "beginBookSearch" {
        
            if !savedSearchKeys.isEmpty {
                
                // searchType = .searchGeneral
                
                SegmentedTableViewCell.emptyCellHeights( tableView )
                generalSearchCoordinator.newQuery( savedSearchKeys, userInitiated: true, refreshControl: nil )
                
                let indexPath = IndexPath( row: Foundation.NSNotFound, section: 0 )
                tableView.scrollToRow( at: indexPath, at: .top, animated: true )
                
                if !(splitViewController?.isCollapsed ?? true) {
                    
                    performSegue(withIdentifier: "displayBlank", sender: self )
                }
            }
            savedIndexPath = nil
        }
    }
    
    // MARK: Sort View Controller
    
    func presentSort() -> Void {
        
        performSegue( withIdentifier: "openBookSort", sender: self )
    }
    
    func saveSortFields( _ sortFields: [SortField] ) -> Void {
        
        generalSearchCoordinator.sortFields = sortFields
    }
    
    @IBAction func dismissSort(_ segue: UIStoryboardSegue) {
        
        if segue.identifier == "beginBookSort" {
            
            savedIndexPath = nil
            tableView.reloadData()
        }
    }
    
    // MARK: Authors Table View Controller
    
    func presentAuthors() -> Void {
        
        performSegue( withIdentifier: "displayGeneralSearchAuthorList", sender: self )
    }
    
    func saveAuthorKey( _ authorKey: String ) -> Void {
        
        savedAuthorKey = authorKey
    }
    
    @IBAction func dismissAuthors(_ segue: UIStoryboardSegue) {
        
        if segue.identifier == "beginAuthorDetail" {
            
            if nil != savedAuthorKey {
                
                // start the next segue AFTER the current segue finishes
                immediateSegueName = "displayGeneralSearchAuthorDetail"
            }
        }
    }
    
    // MARK: query in progress

    func coordinatorIsBusy() -> Void {
        
        activityView?.startAnimating()
        sortButton?.isEnabled = false
        searchButton?.isEnabled = false
        
        SegmentedTableViewCell.emptyIndexPathToKeyLookup( tableView )
    }
    
    func coordinatorIsNoLongerBusy() -> Void {
        
        activityView?.stopAnimating()
        sortButton?.isEnabled = true
        searchButton?.isEnabled = true
    }
    
    // MARK: cell expansion and contraction
    
    fileprivate func expandCell( _ tableView: UITableView, segmentedCell: SegmentedTableViewCell, key: String ) {

        let duration = 0.3
        
        segmentedCell.setOpen( tableView, key: key )
        
        UIView.animate(
            withDuration: duration, delay: 0, options: .curveLinear,
            animations: {
                () -> Void in
                
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        ) {
            (finished) -> Void in
            
            _ = segmentedCell.selectedAnimation( tableView, key: key, expandCell: true, animated: true ) {
                
                SegmentedTableViewCell.animationComplete()
            }
        }
    }
    
    fileprivate func contractCell( _ tableView: UITableView, segmentedCell: SegmentedTableViewCell, key: String ) {
        
        let duration = 0.1 // isOpen ? 0.3 : 0.1 // isOpen ? 1.1 : 0.6
        
        _ = segmentedCell.selectedAnimation( tableView, key: key, expandCell: false, animated: true ) {
            
            UIView.animate(
                withDuration: duration, delay: 0.0, options: .curveLinear,
                
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

extension OLSearchResultsTableViewController: TransitionImage {
    
    var transitionRectImageView: UIImageView? {
        
        if let indexPath = indexPathSavedForTransition {
            
            if let cell = tableView.cellForRow( at: indexPath ) as? GeneralSearchResultSegmentedTableViewCell {
                
                return cell.transitionSourceRectView()
            }
            
        } else if let indexPath = tableView.indexPathForSelectedRow {

            if let cell = tableView.cellForRow( at: indexPath ) as? GeneralSearchResultSegmentedTableViewCell {
                
                return cell.transitionSourceRectView()
            }
        }
        
        return nil
    }
}

extension OLSearchResultsTableViewController: TransitionCell {
    
    func transitionRectCellView() -> UITableViewCell? {
        
        var sourceRectView: UITableViewCell?
        
        assert( nil != indexPathSavedForTransition )
        if let indexPath = indexPathSavedForTransition {
            
            sourceRectView = tableView.cellForRow( at: indexPath )
            indexPathSavedForTransition = nil
        }
        
        return sourceRectView
    }
        
}

// MARK: UIScrollViewDelegate

extension OLSearchResultsTableViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging( _ scrollView: UIScrollView, willDecelerate decelerate: Bool ) {
        
        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Change 10.0 to adjust the distance from bottom
        if maximumOffset - currentOffset <= -10.0 {
            
            generalSearchCoordinator.nextQueryPage()
        
        } else if currentOffset <= -10.0 {
            
            navigationController?.setNavigationBarHidden( false, animated: true )
        }
        
    }

    func scrollViewWillEndDragging( _ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint> ) {
        
        // up
        if velocity.y < -1.5 {
            navigationController?.setNavigationBarHidden( false, animated: true )
        }
    }
}

// MARK: UITableViewDelegate

extension OLSearchResultsTableViewController: UITableViewDelegate {
    
    // do not implement this function! The overhead involved in getting the key isn't worth it

    func tableView( _ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath ) -> CGFloat {
        
        let height = SegmentedTableViewCell.estimatedCellHeight
        
//        print( "estimatedHeightForRowAtIndexPath \(indexPath.row) \(height)" )
        return height
    }
    
    func tableView( _ tableView: UITableView, heightForRowAt indexPath: IndexPath ) -> CGFloat {
        
        assert( Thread.isMainThread )

        var height = SegmentedTableViewCell.estimatedCellHeight

        let cell = tableView.cellForRow( at: indexPath ) as? SegmentedTableViewCell
        if let cell = cell {

            height = cell.height( tableView )

        } else {
            
            height = SegmentedTableViewCell.cachedHeightForRowAtIndexPath( tableView, indexPath: indexPath )
        }

//        print( "heightForRowAtIndexPath: \(cell?.key ?? "nil") \(indexPath.row) \(height)" )
        
        return height
    }

    func tableView( _ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath ) {
        
        if let cell = cell as? GeneralSearchResultSegmentedTableViewCell {
            
            _ = cell.selectedAnimation( tableView, key: cell.key )

//            print( "willDisplayCell forRowAtIndexPath \(indexPath.row) \(cell.key)" )
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow( at: indexPath ) as? SegmentedTableViewCell {
        
            if !cell.isExpanded( in: tableView ) {
                
                if !(splitViewController?.isCollapsed ?? true) && indexPath != indexPathSavedForTransition {
                    
                    performSegue( withIdentifier: "displayBlank", sender: self )
                }

                generalSearchCoordinator.didSelectRowAtIndexPath( indexPath )

                expandCell( tableView, segmentedCell: cell, key: cell.key )
            }

            tableView.scrollToRow( at: indexPath, at: .none, animated: true )

//            print( "didSelectRowAtIndexPath \(indexPath.row) \(cell.key)" )

            indexPathSavedForTransition = indexPath
        }
    }
    
    func tableView( _ tableView: UITableView, didDeselectRowAt indexPath: IndexPath ) {
        
        SegmentedTableViewCell.setClosed( tableView, indexPath: indexPath )
        if let cell = tableView.cellForRow( at: indexPath ) as? SegmentedTableViewCell {
            
            cell.setClosed( tableView )
            contractCell( tableView, segmentedCell: cell, key: cell.key )
            
//            print( "didDeselectRowAtIndexPath \(indexPath.row) \(cell.key)" )
        }
    }
    
}

// MARK: UITableviewDataSource

extension OLSearchResultsTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return generalSearchCoordinator.numberOfSections()
    }
    
    func tableView( _ tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        return generalSearchCoordinator.numberOfRowsInSection( section )
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell? = nil
        
        if let expandingCell = tableView.dequeueReusableCell( withIdentifier: GeneralSearchResultSegmentedTableViewCell.nameOfClass ) as? GeneralSearchResultSegmentedTableViewCell {
            
            if let object = generalSearchCoordinator.objectAtIndexPath( indexPath ) {
                
                expandingCell.tableVC = self
                expandingCell.configure( tableView, indexPath: indexPath, key: object.key, data: object )
                generalSearchCoordinator.displayThumbnail( object, cell: expandingCell )
            }
            
//            print( "cellForRowAtIndexPath \(indexPath.row) \(expandingCell.key)" )
        
            cell = expandingCell
        }
        
        return cell!
    }
    
}

