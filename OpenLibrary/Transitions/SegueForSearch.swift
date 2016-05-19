//
//  SegueForSearch.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/16/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class SegueForSearch: UIStoryboardSegue, UIViewControllerTransitioningDelegate {

    override func perform() {
        
        destinationViewController.transitioningDelegate = self
        
        super.perform()
    }


    // MARK: UIViewControllerTransitioningDelegate
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return SearchPresentationAnimator()
        
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return SearchDismissalAnimator()
        
    }
}
