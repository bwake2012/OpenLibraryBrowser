//
//  UIView+nearestCommonSuperview.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 10/26/18.
//  Copyright © 2018 Bob Wakefield. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func nearestCommonSuperview(with otherView: UIView) -> UIView? {
        
        let viewHierarchy = UIView.hierarchyFor(view: self)
        
        var parentView: UIView? = otherView
        while let view = parentView {
            
            if viewHierarchy.contains(view) {
                
                return view
            }
            
            parentView = view.superview
        }
        
        return nil
    }
    
    static private func hierarchyFor(view: UIView?) -> Set<UIView> {
        
        var set: Set<UIView> = []
        var parentView = view
        while let view = parentView {
            
            set.insert(view)
            parentView = view.superview
        }

        return set
    }
}
