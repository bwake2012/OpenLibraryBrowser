//
//  SegueWithTableViewCellZoom.swift
//  MusicBrowse
//
//  Created by Bob Wakefield on 12/23/15.
//  Copyright © 2015 Bob Wakefield. All rights reserved.
//

import UIKit

class SegueWithTableViewCellZoom: UIStoryboardSegue {

    override func perform() {
        
        assert( nil != self.sourceViewController.navigationController )
        assert( self.sourceViewController.navigationController!.delegate is NavigationControllerDelegate )
        if let navController = self.sourceViewController.navigationController {
            if let ncd = navController.delegate as? NavigationControllerDelegate {
                
                var sourceRectView: UIView?
                if let tableViewVC = sourceViewController as? UITableViewController {
                    if let indexPath = tableViewVC.tableView.indexPathForSelectedRow {
                        
                        sourceRectView =
                            tableViewVC.tableView.cellForRowAtIndexPath( indexPath )
                    }
                }

                ncd.pushZoomTransition( TableviewCellZoomTransition( navigationController: navController, operation: .Push, sourceRectView: sourceRectView ) )
            }
        }
        super.perform()
    }
    
}
