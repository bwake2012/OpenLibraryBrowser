//
//  ImageZoomTransition.swift
//  OpenLibrary Browser
//
//  Created by Bob Wakefield on 12/10/15.
//  Copyright © 2015 Bob Wakefield. All rights reserved.
//

import UIKit

class ImageZoomTransition: ZoomTransition {

    var transitionAnimationOptions = UIViewKeyframeAnimationOptions.calculationModeCubic
    
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
        
        var dvc: OLPictureViewController? = nil
        
        if .push == self.operation {
            
            dvc = viewControllerForTransition( viewController: toVC )

        } else {
            
            dvc = viewControllerForTransition( viewController: fromVC )
        }
        
        guard let detailVC = dvc else {
            assert( false, "neither sourceVC nor destinationVC is an OLPictureViewController" )
            transitionContext.completeTransition( true )
            return
        }
        
        let pictureView = detailVC.pictureView
        guard nil != pictureView || .push == self.operation else {
            print( "picture view not set" )
            transitionContext.completeTransition( true )
            return
        }
        
        if let fromView = transitionContext.view( forKey: UITransitionContextViewKey.from ),
           let toView = transitionContext.view( forKey: UITransitionContextViewKey.to ) {
        
            // fix for rotation bug in iOS 9
            let toFinalFrame = transitionContext.finalFrame( for: toVC )
            toVC.view.frame = toFinalFrame
            
            containerView.addSubview( toView )

            var zoomFromViewRect      = CGRect.zero
            var zoomToViewRect        = CGRect.zero
            var fullscreenPictureRect = CGRect.zero
            
            if .push == self.operation {
                
                zoomFromViewRect = containerView.convert( sourceView.bounds, from: sourceView )
            }
            
            if .pop == self.operation {
                
                zoomToViewRect = containerView.convert( sourceView.bounds, from: sourceView )
            }
            
            // If we're pushing, the frame of the large size UIImageView is wildly wrong.
            // We have to calculate it.
            var layoutMargins = toView.layoutMargins
            layoutMargins.top += UIApplication.shared.statusBarFrame.height
            layoutMargins.top += detailVC.navigationController?.navigationBar.frame.height ?? 0
            fullscreenPictureRect =
                CGRect(
                    x: toFinalFrame.origin.x + layoutMargins.left,
                    y: toFinalFrame.origin.y + layoutMargins.top,
                    width: toFinalFrame.width - (layoutMargins.left + layoutMargins.right ),
                    height: toFinalFrame.height - ( layoutMargins.top + layoutMargins.bottom )
                )

            if .push == self.operation {
                
                zoomToViewRect = fullscreenPictureRect
            }
            var zoomRect = fullscreenPictureRect
            
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
 
                zoomRect = animatingImage.aspectFitRect( zoomRect )
            }

            if .push == self.operation {
                zoomToViewRect = zoomRect
            } else {
                zoomFromViewRect = zoomRect
            }
            
//                print( "from:\(zoomFromViewRect) to:\(zoomToViewRect)" )
//                print( "fromVC:\(fromVC.description) toVC:\(toVC.description)" )
            
            fromView.alpha = 1.0
            toView.alpha   = 0.0
//            zoomFromView.alpha = 1.0
//            zoomToView.alpha   = 0.0

            containerView.addSubview( animatingImageView )
            animatingImageView.frame = zoomFromViewRect
            let endingContentMode: UIViewContentMode = .scaleAspectFit
            
            UIView.animateKeyframes(
                    withDuration: self.transitionDuration,
                    delay: 0,
                    options: self.transitionAnimationOptions,
                    animations: {
                        () -> Void in

                        animatingImageView.frame = zoomToViewRect
                        fromView.alpha = 0;
                        toView.alpha = 1;
                        animatingImageView.contentMode = endingContentMode
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
                        animatingImageView.removeFromSuperview()
                    }
                )
        }
    }
}

