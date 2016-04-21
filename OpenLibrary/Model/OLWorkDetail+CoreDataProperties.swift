//
//  OLWorkDetail.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/14/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

extension OLWorkDetail {

    @NSManaged var author_key: String
    @NSManaged var work_key: String
    @NSManaged var index: Int64

    @NSManaged var key: String
    @NSManaged var created: NSDate?
    @NSManaged var last_modified: NSDate?
    @NSManaged var revision: Int64
    @NSManaged var latest_revision: Int64
    @NSManaged var type: String
    
    @NSManaged var title: String
    @NSManaged var subtitle: String
    @NSManaged var authors: [String]
    @NSManaged var translated_titles: [String]
    @NSManaged var subjects: [String]
    @NSManaged var subject_places: [String]
    @NSManaged var subject_times: [String]
    @NSManaged var subject_people: [String]
    @NSManaged var work_description: String
    @NSManaged var dewey_number: [String]
    @NSManaged var lc_classifications: [String]
    @NSManaged var first_sentence: String
    @NSManaged var original_languages: [String]
    @NSManaged var other_titles: [String]
    @NSManaged var first_publish_date: NSDate?
    @NSManaged var links: [[String: String]]
    @NSManaged var notes: String
    // cover_edition of type /type/edition
    @NSManaged var covers: [Int]
    @NSManaged var coversFound: Bool
}
