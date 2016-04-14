//
//  SegueWithImageZoom.swift
//  MusicBrowse
//
//  Created by Bob Wakefield on 12/23/15.
//  Copyright © 2015 Bob Wakefield. All rights reserved.
//

import UIKit

class SegueWithImageZoom: SegueWithZoom {
    
    override func perform() {
        
        assert( nil != self.sourceViewController.navigationController )
        assert( self.sourceViewController.navigationController!.delegate is NavigationControllerDelegate )
        if let ncd = self.sourceViewController.navigationController?.delegate as? NavigationControllerDelegate? {
            
            if let vc = sourceViewController as? ImageViewTransitionSource {
                
                ncd?.setSourceRectView( vc.transitionSourceRectangle() )
            }
            ncd?.pushZoomTransition( ImageZoomTransition() )
        }

        super.perform()
    }
    
}
