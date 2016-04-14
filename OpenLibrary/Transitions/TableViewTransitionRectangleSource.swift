//
//  TransitionRectangleSource.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/12/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

protocol TableViewTransitionRectangleSource {
    
    func transitionSourceRectangle() -> CGRect
    
//    func transitionSourceImageRectangle() -> CGRect
}

extension UITableViewController: TableViewTransitionRectangleSource {
    
    func transitionSourceRectangle() -> CGRect {
        
        var sourceRect = tableView.bounds
        if let indexPath = tableView.indexPathForSelectedRow {
            
            sourceRect = tableView.rectForRowAtIndexPath( indexPath )
            
        } else {
            
            sourceRect = CGRect( x: 0, y: sourceRect.height / 2, width: sourceRect.width, height: 0 )
        }
        
        return sourceRect
    }
}
