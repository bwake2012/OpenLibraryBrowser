//
//  OLAuthorDetail.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/1/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

extension OLAuthorDetail {

    @NSManaged var key: String
    @NSManaged var name: String
    @NSManaged var personal_name: String
    @NSManaged var birth_date: String
    @NSManaged var death_date: String

    @NSManaged var photos: [Int]                // transformable
    @NSManaged var links: [[String: String]]    // transformable
    @NSManaged var bio: String
    @NSManaged var alternate_names: [String]    // transformable
    
    @NSManaged var wikipedia: String
    
    @NSManaged var revision: Int64
    @NSManaged var latest_revision: Int64
    
    @NSManaged var created: NSDate?
    @NSManaged var last_modified: NSDate?
    
    @NSManaged var type: String
    
    @NSManaged var retrieval_date: NSDate
    @NSManaged var provisional_date: NSDate?
    
    @NSManaged var toSearchResults: OLAuthorSearchResult?
}
