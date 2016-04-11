//
//  OLManagedObject.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/19/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import BNRCoreDataStack

typealias ObjectResultClosure = ( objectID: NSManagedObjectID ) -> Void

typealias ImageDisplayClosure = ( localURL: NSURL ) -> Bool

enum HasPhoto: Int {
    case unknown = -1
    case none = 0
    case local = 1
    case olid = 2
    case id = 3
    case authorDetail = 4
    
    func label() -> String {
        
        switch( self ) {
        case .unknown:
            return( "unknown" )
        case .none:
            return( "none" )
        case .local:
            return( "local" )
        case .olid:
            return( "olid" )
        case .id:
            return( "id" )
        case .authorDetail:
            return( "author detail" )
        }
    }
}

class OLManagedObject: NSManagedObject {

    func localURL( key:String, size: String ) -> NSURL {
        
        let docFolder = try! NSFileManager.defaultManager().URLForDirectory( .DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false )
        
        let imagesFolder = docFolder.URLByAppendingPathComponent( "images" )
        
        let parts = key.componentsSeparatedByString( "/" )
        let goodParts = parts.filter { (x) -> Bool in !x.isEmpty }

        let imagesSubFolder = imagesFolder.URLByAppendingPathComponent( goodParts[0] )
        
        try! NSFileManager.defaultManager().createDirectoryAtURL(
            imagesSubFolder, withIntermediateDirectories: true, attributes: nil )
        
        let fileName = "\(goodParts[1])-\(size).jpg"
        let url = imagesSubFolder.URLByAppendingPathComponent( fileName )
        
        return url
    }
    
    var hasImage: Bool { return true }
    var firstImageID: Int { return 0 }
    
    func localURL( size: String ) -> NSURL {
        
        return NSURL()
    }
    
}


