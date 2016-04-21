//
//  OLTitleSearchResult.swift
//  OpenLibraryBrowser
//
//  Created by Bob Wakefield on 4/9/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

extension OLTitleSearchResult {
    
    @NSManaged var sequence: Int64
    @NSManaged var index: Int64
    @NSManaged var key: String
    
    @NSManaged var author_key: [String]
    @NSManaged var author_name: [String]
    @NSManaged var contributor: [String]
    @NSManaged var cover_i: Int64
    @NSManaged var first_publish_year: String
    @NSManaged var has_fulltext: Bool
    @NSManaged var subtitle: String
    @NSManaged var title: String
    @NSManaged var title_suggest: String

//    @NSManaged var toDetail: OLWorkDetail?
    
}
