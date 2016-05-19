//
//  SearchPresentationAnimator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/16/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class SearchPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let damping: CGFloat = 0.5
    
    let velocity: CGFloat = 10.0
    
    func transitionDuration( transitionContext: UIViewControllerContextTransitioning? ) -> NSTimeInterval {
        
        return 1.0
    }
    
    func animateTransition( transitionContext: UIViewControllerContextTransitioning ) {
        
        guard let fromVC = transitionContext.viewControllerForKey( UITransitionContextFromViewControllerKey ) else {
            transitionContext.completeTransition( false )
            return
        }

        guard let toView = transitionContext.viewForKey( UITransitionContextToViewKey ) else {            transitionContext.completeTransition( false )
            return
        }
        
        guard let containerView = transitionContext.containerView() else {
            transitionContext.completeTransition( false )
            return
        }
        
        var fromView = transitionContext.viewForKey( UITransitionContextFromViewKey )
        let hasFromView = nil != fromView
        if !hasFromView {
            
            fromView = fromVC.view
        }
        
        let halfDuration = transitionDuration(transitionContext) / 2.0
        
        toView.frame = CGRect(x: toView.frame.width, y: toView.frame.origin.y, width: toView.frame.width, height: toView.frame.height)
        
        containerView.addSubview(toView)
        
        UIView.animateWithDuration(
                    halfDuration,
                    delay: 0,
                    usingSpringWithDamping: damping,
                    initialSpringVelocity: velocity,
                    options: UIViewAnimationOptions.CurveLinear,
                    animations: {
                            () -> Void in
                            fromView!.transform = CGAffineTransformMakeScale(0.9, 0.9)
                        },
                    completion: {
                        (finished: Bool) -> Void in
                        if finished {
                            UIView.animateWithDuration(
                                halfDuration,
                                delay: 0,
                                usingSpringWithDamping: self.damping,
                                initialSpringVelocity: self.velocity,
                                options: UIViewAnimationOptions.CurveLinear,
                                animations: {
                                    () -> Void in
                                    toView.frame = CGRect(x: 0, y: 0, width: toView.frame.width, height: toView.frame.height)
                                },
                                completion: {
                                    (finished: Bool) -> Void in
                                    if finished {
                                        transitionContext.completeTransition(finished)
                                    }
                            }
                )
            }
        })
    }
}