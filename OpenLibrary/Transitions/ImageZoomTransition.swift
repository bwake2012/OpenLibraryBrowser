//
//  ImageZoomTransition.swift
//  MusicBrowse
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
            
            print( "transitionContext to VC is missing!" )
            return
        }
        guard let toVC = transitionContext.viewController( forKey: UITransitionContextViewControllerKey.to ) else {
            
            print( "transitionContext from VC is missing!" )
            return
        }
        
        let containerView = transitionContext.containerView

        guard let sourceView = self.sourceView else {
            print( "source view not set" )
            return
        }
        
        var dvc = toVC as? OLPictureViewController
        if nil == dvc {
            dvc = fromVC as? OLPictureViewController
        }
        
        guard let detailVC = dvc else {
            print( "neither sourceVC nor destinationVC is an OLPictureViewController" )
            return
        }
        
        guard let pictureView = detailVC.pictureView else {
            print( "picture view not set" )
            return
        }
        
        if let fromView = transitionContext.view( forKey: UITransitionContextViewKey.from ),
           let toView = transitionContext.view( forKey: UITransitionContextViewKey.to ) {
        
            // fix for rotation bug in iOS 9
            let toFinalFrame = transitionContext.finalFrame( for: toVC )
            toVC.view.frame = toFinalFrame
            
            containerView.addSubview( toView )

            let zoomFromView = .push == self.operation ? sourceView : pictureView
            let zoomToView   = .push == self.operation ? pictureView : sourceView

            var zoomFromViewRect = containerView.convert( zoomFromView.frame, from: zoomFromView.superview )
            var zoomToViewRect = containerView.convert( zoomToView.frame, from: zoomToView.superview )
            var fullscreenPictureRect = containerView.convert( detailVC.pictureView.frame, from: detailVC.view )
            
            // if we're pushing, the frame of the large size UIImageView is wildly wrong. We have to calculate it.
            if .push == self.operation {
            
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
            }
            var zoomRect = fullscreenPictureRect
            
            var animatingImage: UIImage? = detailVC.pictureView.image
            if nil == animatingImage {
                if let imgView = sourceView as? UIImageView {
                    
                    animatingImage = imgView.image
                    detailVC.pictureView.image = animatingImage  // placeholder
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
            zoomFromView.alpha = 1.0
            zoomToView.alpha   = 0.0

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

