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
        
        // iOS8, and apparently iOS9, have a bug where viewForKey:to returns nil.
        // The workaround is:
        // A) get the 'toView' from 'toVC'.
        // B) manually add the 'toView' to the container's
        // superview (eg the root window) after the completeTransition
        // call, as automatically happens on iOS7 where things work properly.
        var toView = transitionContext.viewForKey( UITransitionContextToViewKey )
        let toViewNilBug = nil == toView
        if toViewNilBug {
            
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
        let containerSuperView = containerView.superview
        
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
                                if toViewNilBug {
                                    
                                    containerSuperView?.addSubview( toView! )
                                }
                            }
                    })
                }
        })
    }
}
