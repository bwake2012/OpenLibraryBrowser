//
//  SegueWithZoom.swift
//  MusicBrowse
//
//  Created by Bob Wakefield on 12/27/15.
//  Copyright © 2015 Bob Wakefield. All rights reserved.
//

import UIKit

class SegueWithZoom: UIStoryboardSegue {

//    override init(identifier: String?, source: UIViewController, destination: UIViewController) {
//        
//        super.init( identifier: identifier, source: source, destination: destination )
//        
////        if let navController = source.navigationController {
////
////            NavigationControllerDelegate.addDelegateToNavController( navController )
////        }
//    }
    
    func setSourceRectView( sourceView: UIView ) {

        if let nc = self.sourceViewController.navigationController {

            if let ncd = nc.delegate as? NavigationControllerDelegate {

                ncd.setSourceRectView( sourceView )
            }
        }
    }
}
