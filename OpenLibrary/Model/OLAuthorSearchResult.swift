//
//  OLAuthorSearchResult.swift
//  OpenLibraryBrowser
//
//  Created by Bob Wakefield on 2/22/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import BNRCoreDataStack

class OLAuthorSearchResult: OLManagedObject, CoreDataModelable {
    
    // MARK: Search Info
    struct SearchInfo {
        let objectID: NSManagedObjectID
        let key: String
        let work_count: Int
    }
    
    // MARK: Static Properties
    
    static let entityName = "AuthorSearchResult"
    
    @NSManaged var sequence: Int64
    @NSManaged var index: Int64
    @NSManaged var key: String
    @NSManaged var name: String
    @NSManaged var birth_date: NSDate?
    @NSManaged var death_date: NSDate?
    @NSManaged var type: String
    @NSManaged var top_work: String?
    @NSManaged var work_count: Int64

    @NSManaged var toDetail: OLAuthorDetail?

//    var has_photos = true

    var searchInfo: SearchInfo {
        
        return SearchInfo( objectID: self.objectID, key: self.key, work_count: Int( self.work_count ) )
    }
    
    func localURL( size: String ) -> NSURL {
        
        let key = self.key
        return super.localURL( key, size: size )
    }

}
