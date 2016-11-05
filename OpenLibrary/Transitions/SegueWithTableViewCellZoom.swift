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
        
        assert( nil != self.source.navigationController )
        assert( self.source.navigationController!.delegate is NavigationControllerDelegate )
        if let navController = self.source.navigationController {
            if let ncd = navController.delegate as? NavigationControllerDelegate {
                
                var sourceRectView: UIView?
                if let sourceVC = source as? TransitionSourceCell {
                    
                    sourceRectView = sourceVC.transitionSourceRectCellView()
                }
                assert( nil != sourceRectView )
                ncd.pushZoomTransition( TableviewCellZoomTransition( navigationController: navController, operation: .push, sourceRectView: sourceRectView ) )
            }
        }
        super.perform()
    }
    
}
