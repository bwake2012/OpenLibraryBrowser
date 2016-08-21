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

        assert( nil != self.sourceViewController.navigationController )
        assert( self.sourceViewController.navigationController!.delegate is NavigationControllerDelegate )

        if let navController = self.sourceViewController.navigationController {
            
            if let ncd = navController.delegate as? NavigationControllerDelegate {

                ncd.pushZoomTransition(
                    WindowShadeTransition(
                                navigationController: navController,
                                operation: .Push,
                                sourceRectView: nil
                            )
                        )
            }
        }
        super.perform()
    }
    
}
