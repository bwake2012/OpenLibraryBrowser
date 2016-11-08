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
        
        assert( nil != self.source.navigationController )
        assert( self.source.navigationController!.delegate is NavigationControllerDelegate )
        
        if let navController = self.source.navigationController {
            if let ncd = self.source.navigationController?.delegate as? NavigationControllerDelegate {
                
                var sourceRectView: UIView?
                if let vc = source as? UncoverBottomTransitionSource {
                    
                    sourceRectView = vc.uncoverSourceRectangle()
                }
                assert( nil != sourceRectView )
                ncd.pushZoomTransition( UncoverBottomZoomTransition( navigationController: navController, operation: .push, sourceRectView: sourceRectView ) )
            }
        }

        super.perform()
    }
}
