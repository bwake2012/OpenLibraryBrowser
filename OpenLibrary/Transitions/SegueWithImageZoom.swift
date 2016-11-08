//
//  SegueWithImageZoom.swift
//  MusicBrowse
//
//  Created by Bob Wakefield on 12/23/15.
//  Copyright © 2015 Bob Wakefield. All rights reserved.
//

import UIKit

class SegueWithImageZoom: UIStoryboardSegue {
    
    override func perform() {
        
        assert( nil != self.source.navigationController )
        assert( self.source.navigationController!.delegate is NavigationControllerDelegate )
        
        if let navController = self.source.navigationController {
            if let ncd = navController.delegate as? NavigationControllerDelegate {
                
                var sourceRectView: UIImageView?
                if let vc = source as? TransitionSourceImage {
                    
                    sourceRectView = vc.transitionSourceRectImageView()
                }
                assert( nil != sourceRectView )
                ncd.pushZoomTransition( ImageZoomTransition( navigationController: navController, operation: .push, sourceRectView: sourceRectView ) )
            }
        }
        
        super.perform()
    }
    
}
