//
//  OLAuthorDetail.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/1/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import BNRCoreDataStack

class OLAuthorDetail: OLManagedObject, CoreDataModelable {

    // MARK: Search Info
    struct SearchInfo {
        
        let objectID: NSManagedObjectID
        let key: String
    }
    
    static let entityName = "AuthorDetail"
    
    var searchInfo: SearchInfo {
        
        return SearchInfo( objectID: self.objectID, key: self.key )
    }
    
    override var hasImage: Bool {
        
        return 0 < self.photos.count
    }

    override var firstImageID: Int {
        
        return 0 >= self.photos.count ? 0 : self.photos[0]
    }
    
    override func localURL( size: String ) -> NSURL {
        
        return super.localURL( self.key, size: size )
    }
}
