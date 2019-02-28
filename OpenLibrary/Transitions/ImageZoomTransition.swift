//
//  ImageZoomTransition.swift
//  OpenLibrary Browser
//
//  Created by Bob Wakefield on 12/10/15.
//  Copyright © 2015 Bob Wakefield. All rights reserved.
//

import UIKit

class ImageZoomTransition: ZoomTransition {

    var transitionAnimationOptions = UIView.KeyframeAnimationOptions.calculationModeCubic
    
    // MARK: Overrides
    override func animateTransition( using transitionContext: UIViewControllerContextTransitioning ) -> Void {
        
        guard let fromVC = transitionContext.viewController( forKey: UITransitionContextViewControllerKey.from ) else {
            
            assert( false, "transitionContext to VC is missing!" )
            transitionContext.completeTransition( true )
            return
        }
        guard let toVC = transitionContext.viewController( forKey: UITransitionContextViewControllerKey.to ) else {
            
            assert( false, "transitionContext from VC is missing!" )
            transitionContext.completeTransition( true )
            return
        }
        
        let containerView = transitionContext.containerView

        guard let sourceView = self.sourceView else {
            assert( false, "source view not set" )
            transitionContext.completeTransition( true )
            return
        }
        
        var pictureVC: OLPictureViewController?
        
        // fix for rotation bug in iOS 9
        let toFinalFrame = transitionContext.finalFrame( for: toVC )
        toVC.view.frame = toFinalFrame
        
        if .push == self.operation {
            
            pictureVC = viewControllerForTransition( viewController: toVC )
            let navController = pictureVC?.navigationController
            navController?.view.layoutSubviews()
            pictureVC?.view.layoutSubviews()

        } else {
            
            pictureVC = viewControllerForTransition( viewController: fromVC )
        }
        
        guard let detailVC = pictureVC, let pictureView = detailVC.pictureView else {
            assert( false, "neither sourceVC nor destinationVC is an OLPictureViewController" )
            transitionContext.completeTransition( true )
            return
        }
        
        if let fromView = transitionContext.view( forKey: UITransitionContextViewKey.from ),
           let toView = transitionContext.view( forKey: UITransitionContextViewKey.to ) {
        
            containerView.addSubview( toView )

            var zoomFromViewRect      = CGRect.zero
            var zoomToViewRect        = CGRect.zero
            var fullscreenPictureRect = containerView.convert(pictureView.bounds, from: pictureView)
            
            if .push == self.operation {
                
                zoomFromViewRect = containerView.convert( sourceView.bounds, from: sourceView )
                zoomToViewRect = fullscreenPictureRect
            }
            
            if .pop == self.operation {
                
                zoomFromViewRect = fullscreenPictureRect
                zoomToViewRect = containerView.convert( sourceView.bounds, from: sourceView )
            }

            var animatingImage: UIImage? = nil
            if nil != detailVC.pictureView {
                
                animatingImage = detailVC.pictureView.image
            }
            if nil == animatingImage {

                if let imgView = sourceView as? UIImageView {
                    
                    animatingImage = imgView.image
                }
            }
            
            let animatingImageView = UIImageView.init()
 
            if let animatingImage = animatingImage {
                
                animatingImageView.image = animatingImage
 
                fullscreenPictureRect = animatingImage.aspectFitRect( fullscreenPictureRect )
            }
            
            fromView.alpha = 1.0
            toView.alpha   = 0.0

            containerView.addSubview( animatingImageView )
            animatingImageView.contentMode = .scaleAspectFit
            animatingImageView.frame = zoomFromViewRect
            
            UIView.animateKeyframes(
                    withDuration: self.transitionDuration,
                    delay: 0,
                    options: self.transitionAnimationOptions,
                    animations: {
                        () -> Void in

                        animatingImageView.frame = zoomToViewRect
                        fromView.alpha = 0;
                        toView.alpha = 1;
                    },
                    completion: {
                        ( finished: Bool ) -> Void in
                        if transitionContext.transitionWasCancelled {
                            toView.removeFromSuperview()
                            transitionContext.completeTransition( false )
                            fromView.alpha = 1;
                        } else {
                            fromView.removeFromSuperview()
                            transitionContext.completeTransition( true )
                            toView.alpha = 1;
                        }
                        if .push == self.operation && nil == detailVC.pictureView.image {
                            detailVC.pictureView.image = animatingImage
                        }
                        animatingImageView.removeFromSuperview()
                    }
                )
        }
    }
}

