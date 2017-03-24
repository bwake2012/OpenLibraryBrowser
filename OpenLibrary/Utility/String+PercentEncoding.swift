//
//  String+PercentEncoding.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/26/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

extension String {
    
    func encodeForUrl() -> String
    {
        if let result = self.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed ) {
            
            return result
        
        } else {
            
            return self
        }
    }
    
    func decodeFromUrl() -> String
    {
        if let result = self.removingPercentEncoding {
            
            return result
            
        } else {
            
            return self
        }
    }
    
}
