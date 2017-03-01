//
//  SplitViewControllerDelegate.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/1/17.
//  Copyright © 2017 Bob Wakefield. All rights reserved.
//

import UIKit

class SplitViewControllerDelegate: NSObject, UISplitViewControllerDelegate {
    
    public var collapseDetailViewController = true
    
    override init() {
        
        super.init()
    }
    
    func primaryViewController( forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        
        return collapseDetailViewController ? splitViewController.viewControllers.first : nil
    }
    
    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController
        ) -> Bool {
        
        return collapseDetailViewController
    }
}
