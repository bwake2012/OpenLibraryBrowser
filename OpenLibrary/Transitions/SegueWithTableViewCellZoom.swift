//
//  SegueWithTableViewCellZoom.swift
//  MusicBrowse
//
//  Created by Bob Wakefield on 12/23/15.
//  Copyright © 2015 Bob Wakefield. All rights reserved.
//

import UIKit

class SegueWithTableViewCellZoom: SegueWithZoom {

    override func perform() {
        
        assert( nil != self.sourceViewController.navigationController )
        assert( self.sourceViewController.navigationController!.delegate is NavigationControllerDelegate )
        if let ncd = self.sourceViewController.navigationController?.delegate as? NavigationControllerDelegate {
            
            if let tableViewVC = sourceViewController as? UITableViewController {
                if let indexPath = tableViewVC.tableView.indexPathForSelectedRow {
                    
                    ncd.setSourceRectView(
                        tableViewVC.tableView.cellForRowAtIndexPath( indexPath )!
                    )
                }
            }

            ncd.pushZoomTransition( TableviewCellZoomTransition() )
        }
        
        super.perform()
    }
    
}
