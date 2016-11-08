//
//  NSBundle+AppVersion.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 9/16/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

extension Bundle {
    
    class func getAppVersionString() -> String? {

        // First get the nsObject by defining as an optional anyObject
        if let infoDictionary = Bundle.main.infoDictionary {
            
            let tempVersion: AnyObject? = infoDictionary["CFBundleShortVersionString"] as AnyObject?
            let tempBuild: AnyObject? = infoDictionary["CFBundleVersion"] as AnyObject?
            
            // Then just cast the object as a String, but be careful, you may want to double check for nil
            if let version = tempVersion as? String, let build = tempBuild as? String {
            
                return "\(version) (\(build))"
            }
        }
        
        return nil
    }
}
