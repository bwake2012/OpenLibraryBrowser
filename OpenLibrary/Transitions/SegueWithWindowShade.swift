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

        assert( nil != self.source.navigationController )
        assert( self.source.navigationController!.delegate is NavigationControllerDelegate )

        if let navController = self.source.navigationController {
            
            if let ncd = navController.delegate as? NavigationControllerDelegate {

                ncd.pushZoomTransition(
                    WindowShadeTransition(
                                navigationController: navController,
                                operation: .push,
                                sourceRectView: nil
                            )
                        )
            }
        }
        super.perform()
    }
    
}
