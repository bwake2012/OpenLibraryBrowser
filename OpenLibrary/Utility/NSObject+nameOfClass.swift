//
//  NSObject+nameOfClass.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/30/19.
//  Copyright © 2019 Bob Wakefield. All rights reserved.
//

import Foundation

extension NSObject {

    class var nameOfClass: String {
        return NSStringFromClass(self).components(separatedBy: ".").last!
    }

    var nameOfClass: String {
        return NSStringFromClass(type(of: self)).components( separatedBy: "." ).last!
    }
}
