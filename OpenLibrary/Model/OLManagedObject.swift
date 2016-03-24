//
//  OLManagedObject.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/19/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import BNRCoreDataStack

typealias imageDisplayClosure = ( localURL: NSURL ) -> Bool

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
        
//        print( "\(url)" )
        
        return url
    }
    
}

protocol OLObjectWithImages {
    
    func setThumbnailImage( displayImage: imageDisplayClosure )
    func setMediumImage( displayImage: imageDisplayClosure )
    func setLargeImage( displayImage: imageDisplayClosure )
}

