//
//  NSBundle+AppVersion.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 9/16/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

extension NSBundle {
    
    class func getAppVersionString() -> String? {

        // First get the nsObject by defining as an optional anyObject
        if let infoDictionary = NSBundle.mainBundle().infoDictionary {
            
            let tempVersion: AnyObject? = infoDictionary["CFBundleShortVersionString"]
            let tempBuild: AnyObject? = infoDictionary["CFBundleVersion"]
            
            // Then just cast the object as a String, but be careful, you may want to double check for nil
            if let version = tempVersion as? String, build = tempBuild as? String {
            
                return "\(version) (\(build))"
            }
        }
        
        return nil
    }
}