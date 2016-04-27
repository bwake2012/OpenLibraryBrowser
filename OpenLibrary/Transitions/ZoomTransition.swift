//
//  ZoomTransition.swift
//  MusicBrowse
//
//  Created by Bob Wakefield on 12/10/15.
//  Copyright © 2015 Bob Wakefield. All rights reserved.
//

import UIKit

extension UIView {
    
    func dt_takeSnapshot( xOffset: CGFloat, yOffset: CGFloat ) -> UIImage
    {
        // Use pre iOS-7 snapshot API since we need to render views that are off-screen.
        // iOS 7 snapshot API allows us to snapshot only things on screen
        UIGraphicsBeginImageContextWithOptions( self.bounds.size, self.opaque, 0 )
        if let ctx = UIGraphicsGetCurrentContext() {
            
            if xOffset != 0 || yOffset != 0 {
                CGContextTranslateCTM( ctx, -xOffset, -yOffset )
            }

            self.layer.renderInContext( ctx )
        }
        let snapshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return snapshot;
    }
    
    func dt_takeSnapshot() -> UIImage {
        
        return self.dt_takeSnapshot( 0.0, yOffset: 0.0 )
    }
    
}

// MARK - Zoom Transition Unwind Gesture protocol

protocol ZoomTransitionGestureTarget {
    
    func handlePinch( gestureRecognizer: UIPinchGestureRecognizer ) -> Void
    func handleEdgePan( gestureRecognizer: UIScreenEdgePanGestureRecognizer ) -> Void
    
    func addTransitionGesturesToView( view: UIView )
}

// MARK - base class for zoom transitions holds common data and utility functions

class ZoomTransition: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {

    var sourceView: UIView?
    var operation: UINavigationControllerOperation
    var transitionDuration = NSTimeInterval( 0.3 )
    
    var parent: UINavigationController
    var interactive = false
    
    var transitionBackgroundColor = UIColor.whiteColor()
    
    var startScale = CGFloat( 1.0 )
    var shouldCompleteTransition = true
    
    init(
        navigationController: UINavigationController,
        operation: UINavigationControllerOperation,
        sourceRectView: UIView? ) {
        
        self.parent = navigationController
        self.operation = operation
        self.sourceView = sourceRectView
        
        assert( navigationController.delegate is NavigationControllerDelegate )
    }
    
    func animateTransition( transitionContext: UIViewControllerContextTransitioning ) -> Void {
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        
        return self.transitionDuration
    }    

    func animationEnded( transitionCompleted: Bool ) {
        
        if let ncd = self.parent.delegate as? NavigationControllerDelegate {
        
            if transitionCompleted && .Pop == self.operation {
                
                    ncd.popZoomTransition()

            }
        }
    }
}

// MARK - Gesture Handler extension ported from LCZoomExtension
//        https://github.com/mluisbrown/LCZoomTransition

extension ZoomTransition: ZoomTransitionGestureTarget {
    
    func addTransitionGesturesToView( view: UIView ) {
        
        let pinchRecognizer = UIPinchGestureRecognizer.init( target: self, action: #selector(ZoomTransition.handlePinch(_:)) )
        view.addGestureRecognizer( pinchRecognizer )
        
        let edgePanRecognizer =
        UIScreenEdgePanGestureRecognizer.init( target: self, action: #selector(ZoomTransition.handleEdgePan(_:)) )
        edgePanRecognizer.edges = .Left
        view.addGestureRecognizer( edgePanRecognizer )
    }
    
    // MARK - pinch and edge pan gesture recognition handlers ported from LCZoomTransition

    func handlePinch( gr: UIPinchGestureRecognizer ) -> Void {
        
        let scale = gr.scale
        switch gr.state {
            
        case .Began:
            self.interactive = true
            self.startScale = scale
            self.parent.popViewControllerAnimated( true )
            
        case .Changed:
            let percent = 1.0 - scale / self.startScale
            self.shouldCompleteTransition = ( percent > 0.25 )
            
            self.updateInteractiveTransition( percent <= 0.0 ? 0.0 : percent )
            
        case .Ended, .Cancelled:
            if !self.shouldCompleteTransition || gr.state == .Cancelled {
                self.cancelInteractiveTransition()
            } else {
                self.finishInteractiveTransition()
            }
            self.interactive = false
            
        default: break
        }
    }
    
    func handleEdgePan( gr: UIScreenEdgePanGestureRecognizer ) -> Void {
        
        let point = gr.translationInView( gr.view )
        
        switch gr.state {
            
        case .Began:
            self.interactive = true
            self.parent.popViewControllerAnimated( true )
            
        case .Changed:
            let percent = point.x / gr.view!.frame.size.width
            self.shouldCompleteTransition = percent > 0.25
            
            self.updateInteractiveTransition( percent <= 0.0 ? 0.0 : percent )
            
        case .Ended, .Cancelled:
            if !self.shouldCompleteTransition || gr.state == .Cancelled {
                self.cancelInteractiveTransition()
            } else {
                self.finishInteractiveTransition()
            }
            self.interactive = false
            
        default:
            break
            
        }
    }
}

