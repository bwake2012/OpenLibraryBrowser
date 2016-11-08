//
//  OLAuthorsTableViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 10/14/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

typealias SaveAuthorKey = ( _ authorKey: String ) -> Void

class OLAuthorsTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var saveAuthorKey: SaveAuthorKey?

    var queryCoordinator: AuthorsCoordinator?
    var busyCount = 0
    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        assert( nil != queryCoordinator )
        
        self.edgesForExtendedLayout = UIRectEdge()
        navigationController?.navigationBar.isTranslucent = false
        
        self.tableView.estimatedRowHeight = 102.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.tableFooterView = OLTableViewHeaderFooterView.createFromNib()

        queryCoordinator?.updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear( animated )
        
        navigationController?.setNavigationBarHidden( false, animated: animated )
    }
    
    // MARK: Query in Progress
    func coordinatorIsBusy() -> Void {
        
        if 0 == busyCount {
            
            activityIndicator.startAnimating()
        }
        
        busyCount += 1
    }
    
    func coordinatorIsNoLongerBusy() -> Void {
        
        busyCount -= 1
        if 0 == busyCount {
            
            activityIndicator.stopAnimating()
        }
    }
    
}

extension OLAuthorsTableViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging( _ scrollView: UIScrollView, willDecelerate decelerate: Bool ) {
        
        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y
        
        if currentOffset <= -10.0 {
            
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
extension OLAuthorsTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let authorDetail = queryCoordinator?.objectAtIndexPath( indexPath ) {
            
            if let saveAuthorKey = saveAuthorKey {
                
                saveAuthorKey( authorDetail.key )
            }
            
            performSegue( withIdentifier: "beginAuthorDetail", sender: self )
        }
    }
}

// MARK: UITableviewDataSource
extension OLAuthorsTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return queryCoordinator?.numberOfSections() ?? 0
    }
    
    func tableView( _ tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        return queryCoordinator?.numberOfRowsInSection( section ) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AuthorsTableViewCell", for: indexPath) as! AuthorsTableViewCell
        
        _ = queryCoordinator?.displayToCell( cell, indexPath: indexPath )
        
        return cell
    }
}

