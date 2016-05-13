//
//  OLAuthorSearchResult.swift
//  OpenLibraryBrowser
//
//  Created by Bob Wakefield on 4/17/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import BNRCoreDataStack

extension OLAuthorSearchResult {
    
    @NSManaged var sequence: Int64
    @NSManaged var index: Int64
    @NSManaged var key: String
    @NSManaged var name: String
    @NSManaged var birth_date: String
    @NSManaged var death_date: String
    @NSManaged var type: String
    @NSManaged var top_work: String
    @NSManaged var work_count: Int64
    @NSManaged var has_photos: Bool

    @NSManaged var toDetail: OLAuthorDetail?

}
