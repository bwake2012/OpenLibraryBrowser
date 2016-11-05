//
//  UIApplication+topViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 9/1/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

extension UIApplication {

    class func topViewController(
        _ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
    ) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            
            return topViewController( nav.visibleViewController )
        }
        if let tab = base as? UITabBarController {
            
            let moreNavigationController = tab.moreNavigationController
            
            if let top = moreNavigationController.topViewController , top.view.window != nil {
                
                return topViewController(top)
                
            } else if let selected = tab.selectedViewController {
                
                return topViewController( selected )
            }
        }
        if let presented = base?.presentedViewController {
            
            return topViewController( presented )
        }
        return base
    }
}
