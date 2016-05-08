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

enum DeluxeDetail: String {
    
    case unknown     = "unknown"
    case inline      = "DeluxeDetailInlineTableViewCell"
    case block       = "DeluxeDetailBlockTableViewCell"
    case link        = "DeluxeDetailLinkTableViewCell"
    case heading     = "DeluxeDetailHeadingTableViewCell"
    case subheading  = "DeluxeDetailSubheadingTableViewCell"
    case body        = "DeluxeDetailBodyTableViewCell"
    case image       = "DeluxeDetailImageTableViewCell"
}

struct DeluxeData {
    
    let type: DeluxeDetail
    let caption: String
    let value: String
}


class OLManagedObject: NSManagedObject {
    
    var heading: String {
        
        return ""
    }
    
    var subheading: String {
        
        return ""
    }
    
    var defaultImageName: String {
        
        return "96-book.png"
    }

    lazy var deluxeData: [[DeluxeData]] = {
        
        let deluxeData = self.buildDeluxeData()
        
        return deluxeData
    }()
    
    lazy var hasDeluxeData: Bool = {
        
        return 1 < self.deluxeData.count || ( 1 == self.deluxeData.count && 1 < self.deluxeData[0].count )
    }()
    
    func localURL( key:String, size: String, index: Int = 0 ) -> NSURL {
        
        let docFolder = try! NSFileManager.defaultManager().URLForDirectory( .DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false )
        
        let imagesFolder = docFolder.URLByAppendingPathComponent( "images" )
        
        let parts = key.componentsSeparatedByString( "/" )
        let goodParts = parts.filter { (x) -> Bool in !x.isEmpty }

        let imagesSubFolder = imagesFolder.URLByAppendingPathComponent( goodParts[0] )
        
        try! NSFileManager.defaultManager().createDirectoryAtURL(
            imagesSubFolder, withIntermediateDirectories: true, attributes: nil )
        
        var fileName = "\(goodParts[1])-\(size)"
        if 0 < index {
            fileName += "\(index)"
        }
        fileName += ".jpg"
        let url = imagesSubFolder.URLByAppendingPathComponent( fileName )
        
        return url
    }
    
    var hasImage: Bool { return true }
    var firstImageID: Int { return 0 }
    
    func imageID( index: Int ) -> Int {
        
        return 0
    }
    
    func localURL( size: String, index: Int = 0 ) -> NSURL {
        
        return NSURL()
    }
    
    func buildDeluxeData() -> [[DeluxeData]] {
        
        let deluxeData = [[DeluxeData]]()

        return deluxeData
    }
}


