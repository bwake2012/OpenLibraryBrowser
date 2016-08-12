//
//  SegueWithUnfold.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class SegueWithUnfold: UIStoryboardSegue {

    override func perform() {
        
        assert( nil != self.sourceViewController.navigationController )
        assert( self.sourceViewController.navigationController!.delegate is NavigationControllerDelegate )
        
        if let navController = self.sourceViewController.navigationController {
            if let ncd = self.sourceViewController.navigationController?.delegate as? NavigationControllerDelegate {
                
                var sourceRectView: UIView?
                if let vc = sourceViewController as? UncoverBottomTransitionSource {
                    
                    sourceRectView = vc.uncoverSourceRectangle()
                }
                assert( nil != sourceRectView )
                ncd.pushZoomTransition( UncoverBottomZoomTransition( navigationController: navController, operation: .Push, sourceRectView: sourceRectView ) )
            }
        }

        super.perform()
    }
}
