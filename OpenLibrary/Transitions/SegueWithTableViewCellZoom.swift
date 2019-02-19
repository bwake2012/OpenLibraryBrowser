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
        
        guard let source = self.source as? TransitionCell else {
            
            fatalError( "Source VC does not support TransitionSourceCell protocol" )
        }

        guard let navController = self.source.navigationController else {
            
            fatalError( "Source VC not embedded in a navigation controller" )
        }

        guard let ncd = navController.delegate as? NavigationControllerDelegate else {
            
            fatalError( "source VC navigation controller has no NavigationControllerDelegate" )
        }
        
        let sourceRectView = source.transitionRectCellView()
        if nil == sourceRectView {
            print( "error in transition: \(String(describing: self.identifier))" )
            assert( nil != sourceRectView )
        }

        ncd.pushZoomTransition( TableviewCellZoomTransition( navigationController: navController, operation: .push, sourceRectView: sourceRectView ) )

        super.perform()
    }
    
}
