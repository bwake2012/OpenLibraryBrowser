//
//  SegueWithWindowShade.swift
//  MusicBrowse
//
//  Created by Bob Wakefield on 17 August 2016.
//  Copyright © 2015 Bob Wakefield. All rights reserved.
//

import UIKit

class SegueWithWindowShade: UIStoryboardSegue {

    override func perform() {

        guard let navController = self.source.navigationController else {
            
            fatalError( "Source VC not embedded in a navigation controller" )
        }
        
        guard let ncd = navController.delegate as? NavigationControllerDelegate else {
            
            fatalError( "source VC navigation controller has no NavigationControllerDelegate" )
        }
        
        ncd.pushZoomTransition(
            WindowShadeTransition(
                        navigationController: navController,
                        operation: .push,
                        sourceRectView: nil
                    )
                )

        super.perform()
    }
    
}
