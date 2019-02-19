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
    
    func transitionDuration( using transitionContext: UIViewControllerContextTransitioning? ) -> TimeInterval {
        
        return 1.0
    }
    
    func animateTransition( using transitionContext: UIViewControllerContextTransitioning ) {
        
        guard let fromVC = transitionContext.viewController( forKey: UITransitionContextViewControllerKey.from ) else {
            transitionContext.completeTransition( false )
            return
        }

        guard let toView = transitionContext.view( forKey: UITransitionContextViewKey.to ) else {            transitionContext.completeTransition( false )
            return
        }
        
        let containerView = transitionContext.containerView

        var fromView = transitionContext.view( forKey: UITransitionContextViewKey.from )
        let hasFromView = nil != fromView
        if !hasFromView {
            
            fromView = fromVC.view
        }
        
        let halfDuration = transitionDuration(using: transitionContext) / 2.0
        
        toView.frame = CGRect(x: toView.frame.width, y: toView.frame.origin.y, width: toView.frame.width, height: toView.frame.height)
        
        containerView.addSubview(toView)
        
        UIView.animate(
                    withDuration: halfDuration,
                    delay: 0,
                    usingSpringWithDamping: damping,
                    initialSpringVelocity: velocity,
                    options: UIView.AnimationOptions.curveLinear,
                    animations: {
                            () -> Void in
                            fromView!.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                        },
                    completion: {
                        (finished: Bool) -> Void in
                        if finished {
                            UIView.animate(
                                withDuration: halfDuration,
                                delay: 0,
                                usingSpringWithDamping: self.damping,
                                initialSpringVelocity: self.velocity,
                                options: UIView.AnimationOptions.curveLinear,
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
