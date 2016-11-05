//
//  SegueForSearch.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/16/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class SegueForSearch: UIStoryboardSegue {

    override func perform() {
        
        destination.transitioningDelegate = self
        
        super.perform()
    }
}

extension SegueForSearch: UIViewControllerTransitioningDelegate {

    // MARK: UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return SearchPresentationAnimator()
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return SearchDismissalAnimator()
        
    }
}
