//
//  OLWorkDetail.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/14/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

extension OLWorkDetail {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OLWorkDetail> {
        return NSFetchRequest<OLWorkDetail>( entityName: OLWorkDetail.entityName )
    }
    
    @NSManaged var author_key: String
    @NSManaged var index: Int64
    
    @NSManaged var retrieval_date: Date
    @NSManaged var provisional_date: Date?
    @NSManaged var is_provisional: Bool
    
    @NSManaged var has_fulltext: Int16

    @NSManaged var key: String
    @NSManaged var created: Date?
    @NSManaged var last_modified: Date?
    @NSManaged var revision: Int64
    @NSManaged var latest_revision: Int64
    @NSManaged var type: String
    
    @NSManaged var authors: [String]                // array of author OLIDs
    @NSManaged var covers: [Int]
    @NSManaged var coversFound: Bool
    @NSManaged var dewey_number: [String]
    @NSManaged var ebook_count_i: Int64
    @NSManaged var edition_count: Int64
    @NSManaged var first_publish_date: String
    @NSManaged var first_sentence: String
    @NSManaged var lc_classifications: [String]
    @NSManaged var links: [[String: String]]
    @NSManaged var notes: String
    @NSManaged var original_languages: [String]
    @NSManaged var other_titles: [String]
    @NSManaged var subject_people: [String]
    @NSManaged var subject_places: [String]
    @NSManaged var subject_times: [String]
    @NSManaged var subjects: [String]
    @NSManaged var subtitle: String
    @NSManaged var title: String
    @NSManaged var translated_titles: [String]
    @NSManaged var work_description: String

    // cover_edition of type /type/edition
    
    @NSManaged var general_search_result: OLGeneralSearchResult?
}
