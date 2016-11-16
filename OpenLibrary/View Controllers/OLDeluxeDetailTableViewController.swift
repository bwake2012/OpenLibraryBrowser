//
//  OLAuthorDeluxeDetailTableViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/27/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class OLDeluxeDetailTableViewController: UITableViewController {

    var queryCoordinator: OLDeluxeDetailCoordinator?
    
//    var hidesBarsOnSwipe = false
    
    // MARK: UIView
    override func viewDidLoad() {

        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.estimatedRowHeight = 68.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.tableFooterView = UIView(frame: .zero)

        DeluxeDetailHeadingTableViewCell.registerCell( tableView )
        DeluxeDetailSubheadingTableViewCell.registerCell( tableView )
        DeluxeDetailBodyTableViewCell.registerCell( tableView )
        DeluxeDetailImageTableViewCell.registerCell( tableView )
        DeluxeDetailInlineTableViewCell.registerCell( tableView )
        DeluxeDetailBlockTableViewCell.registerCell( tableView )
        DeluxeDetailLinkTableViewCell.registerCell( tableView )
        DeluxeDetailHTMLTableViewCell.registerCell( tableView )
        DeluxeDetailBookDownloadTableViewCell.registerCell( tableView )
        
    }
        
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear( animated )
        
        navigationController?.setNavigationBarHidden( false, animated: animated )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        queryCoordinator?.cancelOperations()
        
        super.viewWillDisappear( animated )
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let queryCoordinator = queryCoordinator {

            if "zoomDeluxeDetailImage" == segue.identifier {
            
                if let destVC = segue.destination as? OLPictureViewController {
                    
                    queryCoordinator.installPictureCoordinator( destVC )
                }
            } else if DeluxeDetail.downloadBook.reuseIdentifier == segue.identifier {
                
                if let destVC = segue.destination as? OLBookDownloadViewController {
                    
                    queryCoordinator.installBookDownloadCoordinator( destVC )
                }
            }
        }
    }

    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        if let queryCoordinator = queryCoordinator {
            
            cell = queryCoordinator.displayToTableViewCell( tableView, indexPath: indexPath )
        }
        
        return cell!
    }
    
    override func numberOfSections( in tableView: UITableView ) -> Int {
    
        var count = 0
    
        if let queryCoordinator = queryCoordinator {
            
            count = queryCoordinator.numberOfSections()
        }
        
        return count
    }
    
    override func tableView( _ tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        var rows = 0
        if let queryCoordinator = queryCoordinator {
            
            rows = queryCoordinator.numberOfRowsInSection( section )
        }
        
        return rows
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let queryCoordinator = queryCoordinator {
            
            queryCoordinator.didSelectRowAtIndexPath( indexPath )
        }
    }
    
    @IBAction func dismiss(_ segue: UIStoryboardSegue) {
        

    }
}

extension OLDeluxeDetailTableViewController: TransitionSourceImage {
    
    func transitionSourceRectImageView() -> UIImageView? {
        
        guard let indexPath = tableView.indexPathForSelectedRow else { return nil }
        
        guard let imageCell = tableView.cellForRow( at: indexPath ) as? DeluxeDetailImageTableViewCell else { return nil }

        return imageCell.deluxeImage
    }
}

extension OLDeluxeDetailTableViewController: TransitionSourceCell {
    
    func transitionSourceRectCellView() -> UITableViewCell? {
        
        var sourceRectView: UITableViewCell?
        
        if let indexPath = tableView.indexPathForSelectedRow {
            
            sourceRectView = tableView.cellForRow( at: indexPath )
            
        } else if let indexPath = tableView.indexPathForRow( at: tableView.center ) {
            
            sourceRectView = tableView.cellForRow( at: indexPath )
        }
        
        return sourceRectView
    }
    
}


