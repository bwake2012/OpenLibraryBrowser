//
//  OLAuthorDetailWorksTableViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/4/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit
import CoreData

//import BNRCoreDataStack

class OLAuthorDetailWorksTableViewController: UIViewController {

    // MARK: Properties
    var searchInfo: OLAuthorSearchResult?

    @IBOutlet var tableView: UITableView!
    
    var parentVC: OLAuthorDetailViewController?
    var queryCoordinator: AuthorWorksCoordinator?
    var indexPathSavedForTransition: IndexPath?
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        assert( nil != queryCoordinator )
        
        self.tableView.estimatedRowHeight = 68.0
        self.tableView.rowHeight = UITableView.automaticDimension

        self.tableView.tableFooterView = OLTableViewHeaderFooterView.createFromNib()
        
        queryCoordinator?.updateUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if "displayWorkDetail" == segue.identifier {
            
            if let destVC = segue.destination as? OLWorkDetailViewController {
                
                if let indexPath = self.tableView.indexPathForSelectedRow {

                    indexPathSavedForTransition = indexPath
                    queryCoordinator!.installWorkDetailCoordinator( destVC, indexPath: indexPath )
                }
            }
        }
    }
    
    // MARK: Query in Progress
    func coordinatorIsBusy() -> Void {
        
        if let parentVC = parent as? OLAuthorDetailViewController {
            
            parentVC.coordinatorIsBusy()
        }
    }
    
    func coordinatorIsNoLongerBusy() -> Void {
        
        if let parentVC = parent as? OLAuthorDetailViewController {
            
            parentVC.coordinatorIsNoLongerBusy()
        }
    }
    
    // MARK: Utility
    
    func refreshQuery( _ refreshControl: UIRefreshControl? ) {
        
        queryCoordinator?.refreshQuery( refreshControl )
    }
}

extension OLAuthorDetailWorksTableViewController: TransitionCell {
    
    func transitionRectCellView() -> UITableViewCell? {
        
        var sourceRectView: UITableViewCell?
        
        assert( nil != indexPathSavedForTransition )
        if let indexPath = indexPathSavedForTransition {
            
            sourceRectView = tableView.cellForRow( at: indexPath )
            indexPathSavedForTransition = nil
        }
        
        assert( nil != sourceRectView )
        
        return sourceRectView
    }
    
}

// MARK: UIScrollViewDelegate

extension OLAuthorDetailWorksTableViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging( _ scrollView: UIScrollView, willDecelerate decelerate: Bool ) {
        
        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Change 10.0 to adjust the distance from bottom
        if maximumOffset - currentOffset <= -10.0 {
            
            queryCoordinator?.nextQueryPage()
            
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
extension OLAuthorDetailWorksTableViewController: UITableViewDelegate {
    
}

// MARK: UITableviewDataSource
extension OLAuthorDetailWorksTableViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        
        return queryCoordinator?.numberOfSections() ?? 0
    }

    func tableView( _ tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        return queryCoordinator?.numberOfRowsInSection( section ) ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "authorWorksEntry", for: indexPath) as! AuthorWorksTableViewCell
        
        _ = queryCoordinator?.displayToCell( cell, indexPath: indexPath )
        
        return cell
    }
}
