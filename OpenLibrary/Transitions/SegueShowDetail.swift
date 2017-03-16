//
//  SegueShowDetail.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/3/17.
//  Copyright © 2017 Bob Wakefield. All rights reserved.
//
// logic copied from StackOverflow post and embellished
// http://stackoverflow.com/questions/28573900/animate-replace-detail-view-in-uisplitviewcontroller/31585980#31585980

import UIKit

class SegueShowDetail: UIStoryboardSegue {
    
    private let showFromScale: CGFloat = 0.8
    private let hideToScale: CGFloat = 1.2
    private let animationDuration: TimeInterval = 0.33
    
    override func perform() {
        
        let sourceVC = self.source 
        let destinationVC = self.destination 
        let animated = true
        
        if let splitVC = sourceVC.splitViewController {

            // splitview with detail is visible, we will show detail with animation
            showDetail( splitVC: splitVC, sourceVC : sourceVC, destinationVC: destinationVC, animated: animated )

        } else if let navController = sourceVC.navigationController {
            
            // there is no split view – just push to navigation controller
            // if there is a navigation controller delegate, push a transition controller onto its stack
            if let ncd = navController.delegate as? NavigationControllerDelegate {

                let transition = chooseTransition( navController: navController, sourceVC: sourceVC )

                ncd.pushZoomTransition( transition )
            }
            
            sourceVC.navigationController?.pushViewController( destinationVC, animated: animated )

        } else {
            // no navigation found, let just present modal
            sourceVC.present( destinationVC, animated: animated, completion: nil )
        }
        
    }
    
    fileprivate func chooseTransition( navController: UINavigationController, sourceVC: UIViewController ) -> ZoomTransition? {
        
        var transition: ZoomTransition?
        if let sourceVC = sourceVC as? TransitionSourceCell {
            
            let sourceRectView = sourceVC.transitionSourceRectCellView()
            
            assert( nil != sourceRectView )
            
            transition = TableviewCellZoomTransition( navigationController: navController, operation: .push, sourceRectView: sourceRectView )
            
        } else if let sourceVC = sourceVC as? TransitionSourceImage {
            
            let sourceRectView = sourceVC.transitionSourceRectImageView()
            
            assert( nil != sourceRectView )
            
            transition = ImageZoomTransition( navigationController: navController, operation: .push, sourceRectView: sourceRectView )
            
        }
 
        return transition
    }
    
    fileprivate func showDetail( splitVC : UISplitViewController, sourceVC : UIViewController, destinationVC : UIViewController, animated : Bool ) {
        
        var navController: UINavigationController? = destinationVC as? UINavigationController
        if nil == navController {
            
            navController = UINavigationController( rootViewController: destinationVC )
            navController?.delegate = NavigationControllerDelegate()
        }

        guard let newDetailNavVC = navController else {

            fatalError( "no detail navigation controller" )
        }
        
        guard let newDetailVC = newDetailNavVC.topViewController else {
            
            fatalError( "new detail nav controller has no top view controller" )
        }
        
        newDetailVC.navigationItem.leftBarButtonItem = splitVC.displayModeButtonItem
        newDetailVC.navigationItem.leftItemsSupplementBackButton = true

        if !animated {
            
            splitVC.showDetailViewController( newDetailNavVC, sender: sourceVC )
            
        } else {
            
            splitVC.showDetailViewController( newDetailNavVC, sender: sourceVC )
                
        }
    }
}

