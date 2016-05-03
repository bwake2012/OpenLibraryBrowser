//
//  EditionDetail.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/16/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import BNRCoreDataStack

class OLEditionDetail: OLManagedObject, CoreDataModelable {

    // MARK: Search Info
    struct SearchInfo {
        
        let objectID: NSManagedObjectID
        let key: String
    }
    
    static let entityName = "EditionDetail"
    
    override var heading: String {
        
        return self.title
    }
    
    override var subheading: String {
        
        return self.subtitle
    }
    
    override var defaultImageName: String {
        
        return "96-book.png"
    }
    
    override var hasImage: Bool {
        
        return 0 < self.covers.count
    }
    
    override var firstImageID: Int {
        
        return 0 >= self.covers.count ? 0 : self.covers[0]
    }
    
    override func localURL( size: String, index: Int = 0 ) -> NSURL {
        
        return super.localURL( self.key, size: size, index: index )
    }
}
