//
//  TableviewCellZoomTransition.swift
//  MusicBrowse
//
//  Created by Bob Wakefield on 11/20/15.
//  Copyright © 2015 Bob Wakefield. All rights reserved.
//

//  Ported to Swift from objective-c LCZoomTransition written by mluisbrown
//  https://github.com/mluisbrown/LCZoomTransition
//  Comments copied and sometimes expanded
//  Code rearranged to deal with possible zero height masterBottomView
//  Any new bugs or infelicitous Swift code are all my fault

// Copyright (c) 2013 Michael Brown
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is furnished
// to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit

class TableviewCellZoomTransition: ZoomTransition {

    override func animateTransition( transitionContext: UIViewControllerContextTransitioning ) -> Void {

        guard let fromVC = transitionContext.viewControllerForKey( UITransitionContextFromViewControllerKey ) else {
            
            print( "transitionContext to VC is missing!" )
            return
        }
        guard let toVC = transitionContext.viewControllerForKey( UITransitionContextToViewControllerKey ) else {
            
            print( "transitionContext from VC is missing!" )
            return
        }
        
        guard let inView = transitionContext.containerView() else {
            
            print( "transitionContext containerView is missing!" )
            return
        }
        let masterView = self.operation == .Push ? fromVC.view : toVC.view
        let detailView = self.operation == .Push ? toVC.view : fromVC.view
        
        if self.operation == .Push {
            detailView!.frame = transitionContext.finalFrameForViewController( toVC )
        } else {
            masterView.frame = transitionContext.finalFrameForViewController( toVC )
        }
        
        let initialAlpha = CGFloat( self.operation == .Push ? 0.0 : 1.0 )
        let finalAlpha   = CGFloat( self.operation == .Push ? 1.0 : 0.0 )
        
        // add the to VC's view to the intermediate view (where it has to be at the
        // end of the transition anyway). We'll hide it during the transition with
        // a blank view. This ensures that renderInContext of the 'To' view will
        // always render correctly
        inView.addSubview( toVC.view )
        
        // if the detail view is a UIScrollView (eg a UITableView) then
        // get its content offset so we get the snapshot correctly
        var detailContentOffset = CGPointMake( 0.0, 0.0 )
        if let dv = detailView as? UIScrollView {
            
            detailContentOffset = dv.contentOffset
        }
        
        // if the master view is a UIScrollView (eg a UITableView) then
        // get its content offset so we get the snapshot correctly and
        // so we can correctly calculate the split point for the zoom effect
        var masterContentOffset = CGPointMake( 0.0, 0.0 )
        if let mv = masterView as? UIScrollView {
            
            masterContentOffset = mv.contentOffset
        }
        
        // Take a snapshot of the detail view
        // use renderInContext: instead of the new iOS7 snapshot API as that
        // only works for views that are currently visible in the view hierarchy
        let detailSnapshot = detailView.dt_takeSnapshot( 0, yOffset: detailContentOffset.y )
        
        // take a snapshot of the master view
        // use renderInContext: instead of the new iOS7 snapshot API as that
        // only works for views that are currently visible in the view hierarchy
        let masterSnapshot = masterView.dt_takeSnapshot( 0, yOffset: masterContentOffset.y )
        
        // get the rect of the source cell in the coords of the from view
        let sourceViewRect = masterView.convertRect( self.sourceView!.bounds, fromView: self.sourceView )
        let splitPoint = sourceViewRect.origin.y - masterContentOffset.y
        let scale = UIScreen.mainScreen().scale
        
        // split the master view snapshot into two parts, splitting
        // above the master view (usually a UITableViewCell) that originated the transition
        let masterImageRef = masterSnapshot.CGImage
        let topImageRef = CGImageCreateWithImageInRect( masterImageRef, CGRectMake( 0, 0, masterSnapshot.size.width * scale, splitPoint * scale) )
        let topImage = UIImage.init( CGImage: topImageRef!, scale: scale, orientation: .Up )
//        CGImageRelease( topImageRef )
        
        // create views for the top and bottom parts of the master view
        let masterTopView = UIImageView.init( image: topImage )

        // setup the inital and final frames for the master view top and bottom
        // views depending on whether we're doing a push or a pop transition
        var masterTopEndFrame = masterTopView.frame
        if self.operation == .Push {
            
            masterTopEndFrame.origin.y -= masterTopEndFrame.size.height
            
        } else {
            
            var masterTopStartFrame = masterTopView.frame
            masterTopStartFrame.origin.y -= masterTopStartFrame.height
            masterTopView.frame = masterTopStartFrame
        }
        
        let bottomHeight = (masterSnapshot.size.height - splitPoint) * scale
        var masterBottomView: UIImageView?
        var masterBottomFadeView: UIView?
        var masterBottomEndFrame = CGRectMake( 0, 0, 0, 0 )
        if bottomHeight > 0 {

            let bottomImageRef = CGImageCreateWithImageInRect( masterImageRef, CGRectMake(0, splitPoint * scale,  masterSnapshot.size.width * scale, bottomHeight ) )
            let bottomImage = UIImage.init( CGImage: bottomImageRef!, scale: scale, orientation: .Up )
//          CGImageRelease( bottomImageRef )
        
            // create views for the top and bottom parts of the master view
            masterBottomView = UIImageView.init( image: bottomImage )
            var bottomFrame = masterBottomView!.frame
            bottomFrame.origin.y = splitPoint
            masterBottomView!.frame = bottomFrame

            // setup the inital and final frames for the master view top and bottom
            // views depending on whether we're doing a push or a pop transition
            masterBottomEndFrame = masterBottomView!.frame
            if self.operation == .Push {
                
                masterBottomEndFrame.origin.y += masterBottomEndFrame.size.height
                
            } else {
                
                var masterBottomStartFrame = masterBottomView!.frame
                masterBottomStartFrame.origin.y += masterBottomStartFrame.size.height
                masterBottomView!.frame = masterBottomStartFrame
            }
 
            if let mbv = masterBottomView {
                
                masterBottomFadeView = UIView.init( frame: bottomFrame )
                masterBottomFadeView!.backgroundColor = mbv.backgroundColor
                masterBottomFadeView!.alpha = initialAlpha
            }
        }

        // create views to cover the master top and bottom views so that
        // we can fade them in / out
        let masterTopFadeView = UIView.init( frame: masterTopView.frame )
        masterTopFadeView.backgroundColor = masterTopView.backgroundColor
        masterTopFadeView.alpha = initialAlpha
        
        // create snapshot view of the to view
        let detailSmokeScreenView = UIImageView( image: detailSnapshot )
        // for a push transition, make the detail view small, to be zoomed in
        // for a pop transition, the detail view will be zoomed out, so it starts without
        // a transform
        if self.operation == .Push {
            
            detailSmokeScreenView.layer.transform =
                CATransform3DMakeAffineTransform( CGAffineTransformMakeScale( 0.1, 0.1 ) );
        }
        
        // create a background view so that we don't see the actual VC
        // views anywhere - start with a blank canvas.
        let backgroundView = UIView.init( frame: inView.frame )
        backgroundView.backgroundColor = self.transitionBackgroundColor
        
        // add all the views to the transition view
        inView.addSubview( backgroundView )
        inView.addSubview( detailSmokeScreenView )
        inView.addSubview( masterTopView )
        inView.addSubview( masterTopFadeView )

        if let mbv = masterBottomView {
            inView.addSubview( mbv )
        }
        if let mbfv = masterBottomFadeView {
            inView.addSubview( mbfv )
        }
        
        let totalDuration = self.transitionDuration( transitionContext )
        
        UIView.animateKeyframesWithDuration(
            totalDuration,
            delay: 0,
            options: .CalculationModeLinear,
            animations: { () -> Void in
                
                // move the master view top and bottom views (and their
                // respective fade views) to where we want them to end up
                masterTopView.frame = masterTopEndFrame
                masterTopFadeView.frame = masterTopEndFrame
                
                masterBottomView?.frame = masterBottomEndFrame
                masterBottomFadeView?.frame = masterBottomEndFrame
                
                // zoom the detail view in or out, depending on whether we're doing a push
                // or pop transition
                if self.operation == .Push {
                    detailSmokeScreenView.layer.transform =
                        CATransform3DMakeAffineTransform(CGAffineTransformIdentity)
                } else {
                    detailSmokeScreenView.layer.transform =
                        CATransform3DMakeAffineTransform(CGAffineTransformMakeScale( 0.1, 0.1))
                }
                
                // fade out (or in) the master view top and bottom views
                // want the fade out animation to happen near the end of the transition
                // and the fade in animation to happen at the start of the transition
                let fadeStartTime = self.operation == .Push ? 0.5 : 0.0
                UIView.addKeyframeWithRelativeStartTime( fadeStartTime, relativeDuration: 0.5 ) { () -> Void in
                    
                    masterTopFadeView.alpha = finalAlpha
                    masterBottomFadeView?.alpha = finalAlpha
                }
            }) {
                
                ( finished ) -> Void in
                
                // remove all the intermediate views from the hierarchy
                backgroundView.removeFromSuperview()
                detailSmokeScreenView.removeFromSuperview()
                masterTopView.removeFromSuperview()
                masterTopFadeView.removeFromSuperview()

                masterBottomView?.removeFromSuperview()
                masterBottomFadeView?.removeFromSuperview()
                
                if transitionContext.transitionWasCancelled() {
                    
                    // we added this at the start, so we have to remove it
                    // if the transition is canccelled
                    toVC.view.removeFromSuperview()
                    transitionContext.completeTransition( false )
                } else {

                    fromVC.view.removeFromSuperview()
                    transitionContext.completeTransition( true )
                }
                
            }
    }
    
}

