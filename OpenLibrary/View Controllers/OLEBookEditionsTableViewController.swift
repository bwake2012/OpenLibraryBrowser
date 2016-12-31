//
//  OLEBookEditionsTableViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 7/20/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class OLEBookEditionsTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var queryCoordinator: EBookEditionsCoordinator?
    var indexPathSavedForTransition: IndexPath?
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        assert( nil != queryCoordinator )
        
//        refreshControl?.addTarget(
//                self,
//                action: #selector(OLEBookEditionsTableViewController.testRefresh(_:)),
//                forControlEvents: UIControlEvents.ValueChanged
//            )

        self.tableView.estimatedRowHeight = 68.0
        self.tableView.rowHeight = UITableViewAutomaticDimension

        self.tableView.tableFooterView = OLTableViewHeaderFooterView.createFromNib()

        queryCoordinator?.updateUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let segueName = segue.identifier {
            
            if segueName == "EbookEditionTableViewCell" {
                
                if let destVC = segue.destination as? OLBookDownloadViewController {
                    
                    queryCoordinator!.installBookDownloadCoordinator( destVC )
                }
            }
        }
    }
    
    // MARK: dismiss model view controller
    @IBAction func dismiss(_ segue: UIStoryboardSegue) {
        
        
    }

    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        // Dynamic sizing for the header view
        if let footerView = tableView.tableFooterView {
            let height = footerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
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
    
//    // MARK: UIRefreshControl
//    func testRefresh( refreshControl: UIRefreshControl ) {
//        
//        refreshControl.attributedTitle = NSAttributedString( string: "Refreshing data..." )
//        
//        queryCoordinator?.refreshQuery( self.refreshControl )
//    }
}

extension OLEBookEditionsTableViewController: TransitionSourceCell {
    
    func transitionSourceRectCellView() -> UITableViewCell? {
        
        var sourceRectView: UITableViewCell?
        
        assert( nil != indexPathSavedForTransition )
        if let indexPath = indexPathSavedForTransition {
            
            sourceRectView = tableView.cellForRow( at: indexPath )
            indexPathSavedForTransition = nil
        }
        
        return sourceRectView
    }
    
}

// MARK: UITableViewDelegate
extension OLEBookEditionsTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        indexPathSavedForTransition = indexPath
        queryCoordinator?.didSelectItemAtIndexPath( indexPath )
    }
}

// MARK: UITableviewDataSource
extension OLEBookEditionsTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return queryCoordinator?.numberOfSections() ?? 0
    }

    func tableView( _ tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        return queryCoordinator?.numberOfRowsInSection( section ) ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "EbookEditionTableViewCell", for: indexPath)
        if let cell = cell as? EbookEditionTableViewCell {
            
            _ = queryCoordinator?.displayToCell( cell, indexPath: indexPath )
            
        }
        
        return cell
    }
}

