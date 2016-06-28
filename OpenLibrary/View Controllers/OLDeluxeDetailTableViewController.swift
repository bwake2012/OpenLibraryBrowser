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
    
    override func viewWillDisappear(animated: Bool) {
        
        queryCoordinator?.cancelOperations()
        
        super.viewWillDisappear( animated )
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let queryCoordinator = queryCoordinator {

            if "zoomDeluxeDetailImage" == segue.identifier {
            
                if let destVC = segue.destinationViewController as? OLPictureViewController {
                    
                    queryCoordinator.installPictureCoordinator( destVC )
                }
            } else if DeluxeDetail.downloadBook.reuseIdentifier == segue.identifier {
                
                if let destVC = segue.destinationViewController as? OLBookDownloadViewController {
                    
                    queryCoordinator.installBookDownloadCoordinator( destVC )
                }
            }
        }
    }

    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        if let queryCoordinator = queryCoordinator {
            
            cell = queryCoordinator.displayToTableViewCell( tableView, indexPath: indexPath )
        }
        
        return cell!
    }
    
    override func numberOfSectionsInTableView( tableView: UITableView ) -> Int {
    
        var count = 0
    
        if let queryCoordinator = queryCoordinator {
            
            count = queryCoordinator.numberOfSections()
        }
        
        return count
    }
    
    override func tableView( tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        
        var rows = 0
        if let queryCoordinator = queryCoordinator {
            
            rows = queryCoordinator.numberOfRowsInSection( section )
        }
        
        return rows
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let queryCoordinator = queryCoordinator {
            
            queryCoordinator.didSelectRowAtIndexPath( indexPath )
        }
    }
    
    @IBAction func dismiss(segue: UIStoryboardSegue) {
        

    }
}

extension OLDeluxeDetailTableViewController: ImageViewTransitionSource {
    
    func transitionSourceRectangle() -> UIImageView? {
        
        guard let indexPath = tableView.indexPathForSelectedRow else { return nil }
        
        guard let imageCell = tableView.cellForRowAtIndexPath( indexPath ) as? DeluxeDetailImageTableViewCell else { return nil }

        return imageCell.deluxeImage
    }
}


