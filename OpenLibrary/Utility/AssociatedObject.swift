//
//  AssociatedObject.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 8/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

func associatedObject<ValueType: AnyObject>(
    base: AnyObject,
    key: UnsafePointer<UInt8>,
    initialiser: () -> ValueType
    ) -> ValueType {
        if let associated = objc_getAssociatedObject( base, key ) as? ValueType { return associated }
        let associated = initialiser()
        objc_setAssociatedObject( base, key, associated, .OBJC_ASSOCIATION_RETAIN )
        return associated
}

func associateObject<ValueType: AnyObject>(
    base: AnyObject,
    key: UnsafePointer<UInt8>,
    value: ValueType
    ) {
    objc_setAssociatedObject( base, key, value, .OBJC_ASSOCIATION_RETAIN )
}