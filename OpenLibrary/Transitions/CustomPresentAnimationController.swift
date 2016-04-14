//
//  CustomPresentAnimationController.swift
//  MusicBrowse
//
//  Created by Bob Wakefield on 11/19/15.
//  Copyright © 2015 Bob Wakefield. All rights reserved.
//

import UIKit
import Foundation

class CustomPresentAnimationController: NSObject, UIViewControllerAnimatedTransitioning {

    var reverse = false

    func transitionDuration( transitionContext: UIViewControllerContextTransitioning? ) -> NSTimeInterval {
        return 2.5
    }
    
    func animateTransition( transitionContext: UIViewControllerContextTransitioning ) {
        
        let containerView = transitionContext.containerView()
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toView = toViewController.view
        let fromView = fromViewController.view
        let direction = ( reverse ? -1.0 : 1.0 ) as CGFloat
        let const = -0.005 as CGFloat
        
        toView.layer.anchorPoint = CGPointMake(direction == 1 ? 0 : 1, 0.5)
        fromView.layer.anchorPoint = CGPointMake(direction == 1 ? 1 : 0, 0.5)
        
        var viewFromTransform: CATransform3D = CATransform3DMakeRotation(direction * CGFloat(M_PI_2), 0.0, 1.0, 0.0)
        var viewToTransform: CATransform3D = CATransform3DMakeRotation(-direction * CGFloat(M_PI_2), 0.0, 1.0, 0.0)
        viewFromTransform.m34 = const
        viewToTransform.m34 = const
        
        containerView!.transform = CGAffineTransformMakeTranslation(direction * containerView!.frame.size.width / 2.0, 0)
        toView.layer.transform = viewToTransform
        containerView!.addSubview(toView)
        
        UIView.animateWithDuration(transitionDuration(transitionContext), animations: {
            containerView!.transform = CGAffineTransformMakeTranslation(-direction * containerView!.frame.size.width / 2.0, 0)
            fromView.layer.transform = viewFromTransform
            toView.layer.transform = CATransform3DIdentity
            }, completion: {
                finished in
                containerView!.transform = CGAffineTransformIdentity
                fromView.layer.transform = CATransform3DIdentity
                toView.layer.transform = CATransform3DIdentity
                fromView.layer.anchorPoint = CGPointMake(0.5, 0.5)
                toView.layer.anchorPoint = CGPointMake(0.5, 0.5)
                
                if (transitionContext.transitionWasCancelled()) {
                    toView.removeFromSuperview()
                } else {
                    fromView.removeFromSuperview()
                }
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })        
    }
}
