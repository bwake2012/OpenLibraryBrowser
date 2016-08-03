//
//  SearchDismissalAnimator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/16/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class SearchDismissalAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let damping: CGFloat = 0.5
    
    let velocity: CGFloat = 10.0
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        
        return 1.0
        
    }
    
    func animateTransition( transitionContext: UIViewControllerContextTransitioning ) {
        
        guard let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey) else {
            print( "missing animateTransition fromView" )
            assert( false )
            return
        }
        
        var toView = transitionContext.viewForKey( UITransitionContextToViewKey )
        guard nil != toView else {
            
            print( "missing animateTransition toView" )
//            assert( false )
            return
        }
        if nil == toView {
            
            if let toVC = transitionContext.viewControllerForKey( UITransitionContextToViewControllerKey ) {
                toView = toVC.view
                assert( nil != toView )
            }
        }
        
        guard let containerView = transitionContext.containerView() else {
            print( "missing animateTransition containerView" )
            assert( false )
            return
        }
        
        let duration = transitionDuration( transitionContext )
        let halfDuration = duration / 2.0
        
        containerView.insertSubview(toView!, belowSubview: fromView )
        
        toView!.transform = CGAffineTransformMakeScale(0.9, 0.9)
        
        UIView.animateWithDuration(
            halfDuration,
            delay: 0.0,
            usingSpringWithDamping: damping,
            initialSpringVelocity: velocity,
            options: UIViewAnimationOptions.CurveLinear,
            animations: {
                () -> Void in
                fromView.frame = CGRect(x: fromView.frame.width, y: fromView.frame.origin.y, width: fromView.frame.width, height: fromView.frame.height);
            },
            completion: { (finished: Bool) -> Void in
                if finished {
                    UIView.animateWithDuration(
                        halfDuration,
                        delay: 0.0,
                        usingSpringWithDamping: self.damping,
                        initialSpringVelocity: self.velocity,
                        options: UIViewAnimationOptions.CurveLinear,
                        animations: {
                            () -> Void in
                            toView!.transform = CGAffineTransformIdentity
                        }, completion: { (finished: Bool) -> Void in
                            if finished {
                                transitionContext.completeTransition( true )
                            }
                    })
                }
        })
    }
}
