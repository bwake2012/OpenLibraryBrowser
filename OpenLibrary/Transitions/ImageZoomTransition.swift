//
//  ImageZoomTransition.swift
//  MusicBrowse
//
//  Created by Bob Wakefield on 12/10/15.
//  Copyright © 2015 Bob Wakefield. All rights reserved.
//

import UIKit

class ImageZoomTransition: ZoomTransition {

    var transitionAnimationOptions = UIViewKeyframeAnimationOptions.CalculationModeCubic
    
    // MARK: Overrides
    override func animateTransition( transitionContext: UIViewControllerContextTransitioning ) -> Void {
        
        guard let fromVC = transitionContext.viewControllerForKey( UITransitionContextFromViewControllerKey ) else {
            
            print( "transitionContext to VC is missing!" )
            return
        }
        guard let toVC = transitionContext.viewControllerForKey( UITransitionContextToViewControllerKey ) else {
            
            print( "transitionContext from VC is missing!" )
            return
        }
        
        guard let containerView = transitionContext.containerView() else {
            
            print( "transitionContext containerView is missing!" )
            return
        }
        
        guard let sourceView = self.sourceView else {
            print( "source view not set" )
            return
        }
        
        if let fromView = transitionContext.viewForKey( UITransitionContextFromViewKey ),
            toView = transitionContext.viewForKey( UITransitionContextToViewKey ) {
        
            // fix for rotation bug in iOS 9
            let toFinalFrame = transitionContext.finalFrameForViewController( toVC )
            toVC.view.frame = toFinalFrame
            
            containerView.addSubview( toView )

            var detailVC = toVC as? OLPictureViewController
            if nil == detailVC {
                detailVC = fromVC as? OLPictureViewController
            }
            
            if let dvc = detailVC {
                let zoomFromView = .Push == self.operation ? sourceView : dvc.pictureView
                let zoomToView   = .Push == self.operation ? dvc.pictureView : sourceView

                var zoomFromViewRect = containerView.convertRect( zoomFromView.frame, fromView: zoomFromView.superview )
                var zoomToViewRect   = containerView.convertRect( zoomToView.frame, fromView: zoomToView.superview )
                var fullscreenPictureRect = containerView.convertRect( dvc.pictureView.frame, fromView: dvc.view )
                
                // if we're pushing, the frame of the large size UIImageView is wildly wrong. We have to calculate it.
                if .Push == self.operation {
                
                    var layoutMargins = toView.layoutMargins
                    layoutMargins.top += UIApplication.sharedApplication().statusBarFrame.height
                    layoutMargins.top += dvc.navigationController?.navigationBar.frame.height ?? 0
                    fullscreenPictureRect =
                        CGRect(
                            x: toFinalFrame.origin.x + layoutMargins.left,
                            y: toFinalFrame.origin.y + layoutMargins.top,
                            width: toFinalFrame.width - (layoutMargins.left + layoutMargins.right ),
                            height: toFinalFrame.height - ( layoutMargins.top + layoutMargins.bottom )
                        )
                }
                var zoomRect = fullscreenPictureRect
                
                var animatingImage: UIImage? = dvc.pictureView.image
                if nil == animatingImage {
                    if let imgView = sourceView as? UIImageView {
                        
                        animatingImage = imgView.image
                        dvc.pictureView.image = animatingImage  // placeholder
                    }
                }
                
                let animatingImageView = UIImageView.init()
     
                if let animatingImage = animatingImage {
                    
                    animatingImageView.image = animatingImage
     
                    zoomRect = animatingImage.aspectFitRect( zoomRect )
                }

                if .Push == self.operation {
                    zoomToViewRect = zoomRect
                } else {
                    zoomFromViewRect = zoomRect
                }
                
//                print( "from:\(zoomFromViewRect) to:\(zoomToViewRect)" )
//                print( "fromVC:\(fromVC.description) toVC:\(toVC.description)" )
                
                fromView.alpha = 1.0
                toView.alpha   = 0.0
                zoomFromView.alpha = 1.0
                zoomToView.alpha   = 0.0

                containerView.addSubview( animatingImageView )
                animatingImageView.frame = zoomFromViewRect
                let endingContentMode: UIViewContentMode = .ScaleAspectFit
                
                UIView.animateKeyframesWithDuration(
                        self.transitionDuration,
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
                            if transitionContext.transitionWasCancelled() {
                                toView.removeFromSuperview()
                                transitionContext.completeTransition( false )
                                zoomFromView.alpha = 1;
                            } else {
                                fromView.removeFromSuperview()
                                transitionContext.completeTransition( true )
                                zoomToView.alpha = 1;
                            }
                            animatingImageView.removeFromSuperview()
                        }
                    )
            }
        }
    }
}

