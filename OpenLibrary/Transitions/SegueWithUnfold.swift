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
        
        guard let source = self.source as? UncoverBottomTransitionSource else {
            
            fatalError( "Source VC does not support UncoverBottomTransitionSource protocol" )
        }
        
        guard let navController = self.source.navigationController else {
            
            fatalError( "Source VC not embedded in a navigation controller" )
        }
        
        guard let ncd = navController.delegate as? NavigationControllerDelegate else {
            
            fatalError( "source VC navigation controller has no NavigationControllerDelegate" )
        }
        
        let sourceRectView = source.uncoverSourceRectangle()

        ncd.pushZoomTransition( UncoverBottomZoomTransition( navigationController: navController, operation: .push, sourceRectView: sourceRectView ) )

        super.perform()
    }
}
