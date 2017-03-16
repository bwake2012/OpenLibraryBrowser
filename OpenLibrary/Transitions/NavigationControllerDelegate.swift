//
//  NavigationControllerDelegate.swift
//  TestTransitions2
//
//  Created by Bob Wakefield on 12/8/15.
//  Copyright © 2015 Bob Wakefield. All rights reserved.
//

import UIKit

class NavigationControllerDelegate: NSObject, UINavigationControllerDelegate {

    //weak var parent: UINavigationController?
    
    static var delegates = [ UINavigationController: UINavigationControllerDelegate ]()
    
    static var transitionStack = [ZoomTransition?]()
    
    static func addDelegateToNavController( _ navController: UINavigationController ) -> UINavigationControllerDelegate? {
    
        let delegate = navController.delegate
//        assert( nil == delegate || delegate is NavigationControllerDelegate )
//    
//        if nil == delegate {
//            
//            delegate = NavigationControllerDelegate( navController: navController )
//        }
        
        return delegate
    }
    
    override init() {
        
        super.init()
        
//        print( "\(unsafeAddressOf(self)) NavigationControllerDelegate: init" )
    }
    
    deinit {
        
//        print( "\(unsafeAddressOf(self)) NavigationControllerDelegate: deinit " )
    }
    
    // MARK: transition stack maintenance
    
    func pushZoomTransition( _ zoomTransition: ZoomTransition? ) {
        
        NavigationControllerDelegate.transitionStack.append( zoomTransition )
        
//        print( "\(unsafeAddressOf(self)) Push \(self.transitionStack.count) \(zoomTransition.description)" )
    }

    func popZoomTransition() -> ZoomTransition? {
        
        let zoomTransition = NavigationControllerDelegate.transitionStack.removeLast()
        
//        print( "\(unsafeAddressOf(self)) Pop \(self.transitionStack.count) \(zoomTransition.description)" )
        
        return zoomTransition
    }
    
    func currentZoomTransition() -> ZoomTransition? {
        
        var transition: ZoomTransition?
        
        if !NavigationControllerDelegate.transitionStack.isEmpty {
            
            transition = NavigationControllerDelegate.transitionStack.last!
        }
        
        return transition
    }
    
    func transitionStackEmpty() -> Bool {
        
        return NavigationControllerDelegate.transitionStack.isEmpty
    }
    
    // MARK: UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let transition = self.currentZoomTransition()
        if .pop == operation {
            
            transition?.operation = operation
            
        } else {
        
            transition?.addTransitionGesturesToView( toVC.view )
        }

//        print( "\(unsafeAddressOf(self)) operation: \(operation == .Push ? "Push" : "Pop") \(self.transitionStack.count)" )

        return transition
    }
    
    func navigationController( _ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning ) -> UIViewControllerInteractiveTransitioning? {
        
        if let zoomTransition = currentZoomTransition() {
            
            return zoomTransition.interactive ? zoomTransition : nil
        }
            
        return nil
    }
    
}
