//
//  ZoomTransition.swift
//  MusicBrowse
//
//  Created by Bob Wakefield on 12/10/15.
//  Copyright © 2015 Bob Wakefield. All rights reserved.
//

import UIKit

extension UIView {
    
    func dt_takeSnapshot( _ xOffset: CGFloat, yOffset: CGFloat ) -> UIImage
    {
        // Use pre iOS-7 snapshot API since we need to render views that are off-screen.
        // iOS 7 snapshot API allows us to snapshot only things on screen
        UIGraphicsBeginImageContextWithOptions( self.bounds.size, self.isOpaque, 0 )
        if let ctx = UIGraphicsGetCurrentContext() {
            
            if xOffset != 0 || yOffset != 0 {
                ctx.translateBy(x: -xOffset, y: -yOffset )
            }

            self.layer.render( in: ctx )
        }
        let snapshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return snapshot!;
    }
    
    func dt_takeSnapshot() -> UIImage {
        
        return self.dt_takeSnapshot( 0.0, yOffset: 0.0 )
    }
    
}

// MARK - Zoom Transition Unwind Gesture protocol

protocol ZoomTransitionGestureTarget {
    
    func handlePinch( _ gestureRecognizer: UIPinchGestureRecognizer ) -> Void
    func handleEdgePan( _ gestureRecognizer: UIScreenEdgePanGestureRecognizer ) -> Void
    
    func addTransitionGesturesToView( _ view: UIView )
}

// MARK - base class for zoom transitions holds common data and utility functions

class ZoomTransition: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {

    var sourceView: UIView?
    var operation: UINavigationControllerOperation
    var transitionDuration = TimeInterval( 0.3 )
    
    var parent: UINavigationController
    var interactive = false
    
    var transitionBackgroundColor = UIColor.white
    
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
    
    func animateTransition( using transitionContext: UIViewControllerContextTransitioning ) -> Void {
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        return self.transitionDuration
    }    

    func animationEnded( _ transitionCompleted: Bool ) {
        
        if let ncd = self.parent.delegate as? NavigationControllerDelegate {
        
            if transitionCompleted && .pop == self.operation {
                
                _ = ncd.popZoomTransition()

            }
        }
    }
}

// MARK - Gesture Handler extension ported from LCZoomExtension
//        https://github.com/mluisbrown/LCZoomTransition

extension ZoomTransition: ZoomTransitionGestureTarget {
    
    func addTransitionGesturesToView( _ view: UIView ) {
        
//        let pinchRecognizer = UIPinchGestureRecognizer.init( target: self, action: #selector(ZoomTransition.handlePinch(_:)) )
//        view.addGestureRecognizer( pinchRecognizer )
        
        let edgePanRecognizer =
        UIScreenEdgePanGestureRecognizer.init( target: self, action: #selector(ZoomTransition.handleEdgePan(_:)) )
        edgePanRecognizer.edges = .left
        view.addGestureRecognizer( edgePanRecognizer )
    }
    
    // MARK - pinch and edge pan gesture recognition handlers ported from LCZoomTransition

    func handlePinch( _ gr: UIPinchGestureRecognizer ) -> Void {
        
        let scale = gr.scale
        switch gr.state {
            
        case .began:
            self.interactive = true
            self.startScale = scale
            self.parent.popViewController( animated: true )
            
        case .changed:
            let percent = 1.0 - scale / self.startScale
            self.shouldCompleteTransition = ( percent > 0.25 )
            
            self.update( percent <= 0.0 ? 0.0 : percent )
            
        case .ended, .cancelled:
            if !self.shouldCompleteTransition || gr.state == .cancelled {
                self.cancel()
            } else {
                self.finish()
            }
            self.interactive = false
            
        default: break
        }
    }
    
    func handleEdgePan( _ gr: UIScreenEdgePanGestureRecognizer ) -> Void {
        
        let point = gr.translation( in: gr.view )
        
        switch gr.state {
            
        case .began:
            self.interactive = true
            self.parent.popViewController( animated: true )
            
        case .changed:
            let percent = point.x / gr.view!.frame.size.width
            self.shouldCompleteTransition = percent > 0.25
            
            self.update( percent <= 0.0 ? 0.0 : percent )
            
        case .ended, .cancelled:
            if !self.shouldCompleteTransition || gr.state == .cancelled {
                self.cancel()
            } else {
                self.finish()
            }
            self.interactive = false
            
        default:
            break
            
        }
    }
}

extension ZoomTransition {
    
    func viewControllerForTransition< T >( viewController: UIViewController ) -> T? {
        
        var vc: T? = nil
        
        if let navVC = viewController as? UINavigationController {
            
            vc = navVC.topViewController as? T
        }
        
        if nil == vc {
            
            vc = viewController as? T
        }
                
        return vc
    }
    
}

