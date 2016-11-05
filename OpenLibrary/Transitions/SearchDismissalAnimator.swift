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
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        return 1.0
        
    }
    
    func animateTransition( using transitionContext: UIViewControllerContextTransitioning ) {
        
        guard let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from) else {
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
        var toView = transitionContext.view( forKey: UITransitionContextViewKey.to )
        let toViewNilBug = nil == toView
        if toViewNilBug {
            
            if let toVC = transitionContext.viewController( forKey: UITransitionContextViewControllerKey.to ) {
                toView = toVC.view
                assert( nil != toView )
            }
        }
        
        let containerView = transitionContext.containerView
        
        let containerSuperView = containerView.superview
        
        let duration = transitionDuration( using: transitionContext )
        let halfDuration = duration / 2.0
        
        containerView.insertSubview(toView!, belowSubview: fromView )
        
        toView!.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        UIView.animate(
            withDuration: halfDuration,
            delay: 0.0,
            usingSpringWithDamping: damping,
            initialSpringVelocity: velocity,
            options: UIViewAnimationOptions.curveLinear,
            animations: {
                () -> Void in
                fromView.frame = CGRect(x: fromView.frame.width, y: fromView.frame.origin.y, width: fromView.frame.width, height: fromView.frame.height);
            },
            completion: { (finished: Bool) -> Void in
                if finished {
                    UIView.animate(
                        withDuration: halfDuration,
                        delay: 0.0,
                        usingSpringWithDamping: self.damping,
                        initialSpringVelocity: self.velocity,
                        options: UIViewAnimationOptions.curveLinear,
                        animations: {
                            () -> Void in
                            toView!.transform = CGAffineTransform.identity
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
