//
//  WindowShadeTransition.swift
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

class WindowShadeTransition: ZoomTransition {
    
    private struct animaSegment {
        
        let view: UIView
        let fadeView: UIView
        
        var frame: CGRect {
            
            get {
                
                return view.frame
            }
            
            set( newFrame ) {
                
                view.frame = newFrame
                fadeView.frame = newFrame
            }
        }
        
        func setParentView( parentView: UIView ) {
            
            parentView.addSubview( view )
            parentView.addSubview( fadeView )
        }
        
        func removeFromSuperview() {
            
            view.removeFromSuperview()
            fadeView.removeFromSuperview()
        }
    }

    // MARK: Utility
    
    // create either the top or bottom image and fade views plus the ending frame
    // set the initial alpha value on the fade view
    // if the view is zero height or less return nil
    private func animaViews( viewFrame: CGRect, viewSnapshot: UIImage ) -> animaSegment? {
    
        guard 0 < viewFrame.height && 0 < viewFrame.width else { return nil }
            
        let viewSnapshotRef = viewSnapshot.CGImage
        let scale = UIScreen.mainScreen().scale
    
        let imageRef =
            CGImageCreateWithImageInRect(
                    viewSnapshotRef,
                    CGRect(
                        x: viewFrame.origin.x * scale, y: viewFrame.origin.y * scale,
                        width: viewFrame.size.width * scale, height: viewFrame.size.height * scale
                    )
                )
        let image = UIImage.init( CGImage: imageRef!, scale: scale, orientation: .Up )
        //          CGImageRelease( bottomImageRef )
        
        // create views for the top or bottom part of the master view
        let view = UIImageView.init( image: image )
        
        let fadeView = UIView.init( frame: CGRect( origin: CGPoint( x: 0, y: 0 ), size: viewFrame.size ) )
        fadeView.backgroundColor = view.backgroundColor
    
        return animaSegment( view: view, fadeView: fadeView )
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
        let masterVC = self.operation == .Push ? fromVC : toVC
        let detailVC = self.operation == .Push ? toVC   : fromVC
        let masterView = masterVC.view
        let masterFrame = masterView.frame
        let detailView = detailVC.view
        let detailFrame = detailView.frame
                
        let finalFrame = transitionContext.finalFrameForViewController( toVC )
        
        if self.operation == .Push {
            detailView!.frame = finalFrame
        } else {
            masterView.frame = finalFrame
        }
        
        let isNavBarVisible =
            ( .Push == self.operation ) ? ( 0 != masterFrame.origin.y ) : ( 0 != detailFrame.origin.y )

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
        
        let topBarsHeight = masterVC.topLayoutGuide.length
        let topBarsFrame =
                CGRect(
                        origin: masterFrame.origin,
                        size: CGSize( width: masterFrame.width, height: topBarsHeight )
                    )
        var animaTopBars =
            animaViews( topBarsFrame, viewSnapshot: .Push == self.operation ? masterSnapshot : detailSnapshot )
        
        let movingFrame = CGRect( origin: CGPointZero, size: finalFrame.size )
        
        var animaMaster =
            animaViews( isNavBarVisible ? movingFrame : masterFrame, viewSnapshot: masterSnapshot )
        
        var animaDetail = animaViews( isNavBarVisible ? movingFrame : detailFrame, viewSnapshot: detailSnapshot )
        let frameUp =
            CGRect(
                    origin: CGPoint( x: 0, y: topBarsHeight - finalFrame.height ),
                    size: finalFrame.size
                )
        let frameDown = finalFrame
        
        let frameStart = .Push == self.operation ? frameUp   : frameDown
        let frameEnd   = .Push == self.operation ? frameDown : frameUp
        
        // create a background view so that we don't see the actual VC
        // views anywhere - start with a blank canvas.
        let backgroundView = UIView.init( frame: inView.frame )
        backgroundView.backgroundColor = self.transitionBackgroundColor
        
        // create snapshot view of the to view
        let detailSmokeScreenView = UIImageView( image: detailSnapshot )

        // add all the views to the transition view
        inView.addSubview( backgroundView )
        inView.addSubview( detailSmokeScreenView )
        
        animaMaster?.setParentView( inView )
        animaMaster?.frame = finalFrame
        animaDetail?.setParentView( inView )
        animaDetail?.frame = frameStart
        animaTopBars?.setParentView( inView )
        animaTopBars?.frame = topBarsFrame
        animaTopBars?.fadeView.alpha = initialAlpha
        
        let totalDuration = self.transitionDuration( transitionContext ) // * 10
        
        UIView.animateKeyframesWithDuration(
            totalDuration,
            delay: 0,
            options: .CalculationModeLinear,
            animations: { () -> Void in
                
                // move the master view top and bottom views (and their
                // respective fade views) to where we want them to end up
                animaDetail?.frame = frameEnd
                
                // fade out (or in) the master view top and bottom views
                // want the fade out animation to happen near the end of the transition
                // and the fade in animation to happen at the start of the transition
                let fadeStartTime = 0.8 // self.operation == .Push ? 0.8 : 0.0
                UIView.addKeyframeWithRelativeStartTime( fadeStartTime, relativeDuration: 0.2 ) { () -> Void in
                    
                    animaTopBars?.fadeView.alpha = finalAlpha
                }
            }) {
                
                ( finished ) -> Void in
                
                // remove all the intermediate views from the hierarchy
                backgroundView.removeFromSuperview()
                detailSmokeScreenView.removeFromSuperview()
                
                animaMaster?.removeFromSuperview()
                animaDetail?.removeFromSuperview()
                animaTopBars?.removeFromSuperview()

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

