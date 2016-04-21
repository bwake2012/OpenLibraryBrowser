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
    
    private struct animaSegment {
        
        let view: UIView
        let fadeView: UIView
        let endFrame: CGRect
    }

    // MARK: Utility
    
    // create either the top or bottom image and fade views plus the ending frame
    // set the initial alpha value on the fade view
    // if the view is zero height or less return nil
    private func animaViews( isTop: Bool, masterSnapshot: UIImage, splitPoint: CGFloat, initialAlpha: CGFloat ) -> animaSegment? {
    
        let height = isTop ? splitPoint : masterSnapshot.size.height - splitPoint
        guard 0 < height else { return nil }
            
        var endFrame = CGRectMake( 0, 0, 0, 0 )
 
        let masterImageRef = masterSnapshot.CGImage
        let scale = UIScreen.mainScreen().scale
        let y = isTop ? 0.0 : splitPoint * scale
        let deltaY = isTop ? -height : height
    
        let imageRef = CGImageCreateWithImageInRect( masterImageRef, CGRectMake(0, y, masterSnapshot.size.width * scale, height ) )
        let image = UIImage.init( CGImage: imageRef!, scale: scale, orientation: .Up )
        //          CGImageRelease( bottomImageRef )
        
        // create views for the top and bottom parts of the master view
        let view = UIImageView.init( image: image )
        var frame = view.frame
        frame.origin.y = y
        view.frame = frame
        
        // setup the inital and final frames for the master view top and bottom
        // views depending on whether we're doing a push or a pop transition
        endFrame = view.frame
        if self.operation == .Push {
        
            endFrame.origin.y += deltaY
        
        } else {
        
            var startFrame = view.frame
            startFrame.origin.y += deltaY
            view.frame = startFrame
        }
        
        let fadeView = UIView.init( frame: frame )
        fadeView.backgroundColor = view.backgroundColor
        fadeView.alpha = initialAlpha
    
        return animaSegment( view: view, fadeView: fadeView, endFrame: endFrame )
    }
    
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
        
        // split the master view snapshot into two parts, splitting
        // above the master view (usually a UITableViewCell) that originated the transition
        let topAnima =
            animaViews( true, masterSnapshot: masterSnapshot, splitPoint: splitPoint, initialAlpha: initialAlpha )
        
        let bottomAnima =
            animaViews( false, masterSnapshot: masterSnapshot, splitPoint: splitPoint, initialAlpha: initialAlpha )
        
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
        
        if let t = topAnima {
            inView.addSubview( t.view )
            inView.addSubview( t.fadeView )
        }

        if let b = bottomAnima {

            inView.addSubview( b.view )
            inView.addSubview( b.fadeView )
        }
        
        let totalDuration = self.transitionDuration( transitionContext )
        
        UIView.animateKeyframesWithDuration(
            totalDuration,
            delay: 0,
            options: .CalculationModeLinear,
            animations: { () -> Void in
                
                // move the master view top and bottom views (and their
                // respective fade views) to where we want them to end up
                if let t = topAnima {
                    t.view.frame = t.endFrame
                    t.fadeView.frame = t.endFrame
                }
                
                if let b = bottomAnima {
                    b.view.frame = b.endFrame
                    b.fadeView.frame = b.endFrame
                }
                
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
                    
                    topAnima?.fadeView.alpha = finalAlpha
                    bottomAnima?.fadeView.alpha = finalAlpha
                }
            }) {
                
                ( finished ) -> Void in
                
                // remove all the intermediate views from the hierarchy
                backgroundView.removeFromSuperview()
                detailSmokeScreenView.removeFromSuperview()
                topAnima?.view.removeFromSuperview()
                topAnima?.fadeView.removeFromSuperview()

                bottomAnima?.view.removeFromSuperview()
                bottomAnima?.fadeView.removeFromSuperview()
                
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

