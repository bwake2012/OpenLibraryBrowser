//
//  String+NonBreakingSpaces.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 9/22/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

private let nonBreakingSpace = "\u{00a0}"
private let space = " "

extension String {
    
    func stringWithNonBreakingSpaces() -> String {
        
        return self.stringByReplacingOccurrencesOfString( space, withString: nonBreakingSpace )
    }
}