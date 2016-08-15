//
//  OLGeneralSearchResult+CoreDataProperties.swift
//  
//
//  Created by Bob Wakefield on 4/19/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension OLGeneralSearchResult {

    @NSManaged var      sequence: Int64
    @NSManaged var      index: Int64
    @NSManaged var      retrieval_date: NSDate?
    
    @NSManaged var 	    author_key: [String]
    @NSManaged var 	    author_name: [String]
    @NSManaged var 	    cover_edition_key: String
    @NSManaged var 	    cover_i: Int64
    @NSManaged var 	    ebook_count_i: Int64
    @NSManaged var 	    edition_count: Int64
    @NSManaged var 	    edition_key: [String]
    @NSManaged var 	    first_publish_year: String
    @NSManaged var 	    first_sentence: [String]
    @NSManaged var 	    has_fulltext: Bool
    @NSManaged var 	    ia_collection_s: String
    @NSManaged var 	    ia: [String]
    @NSManaged var 	    id_goodreads: [String]
    @NSManaged var 	    id_librarything: [String]
    @NSManaged var 	    isbn: [String]
    @NSManaged var 	    key: String
    @NSManaged var 	    language: [String]
    @NSManaged var      language_names: [String]
    @NSManaged var 	    last_modified_i: Int64
    @NSManaged var 	    lccn: [String]
    @NSManaged var 	    person: [String]
    @NSManaged var 	    printdisabled_s: String
    @NSManaged var 	    public_scan_b: Bool
    @NSManaged var 	    publish_date: [String]
    @NSManaged var 	    publish_place: [String]
    @NSManaged var 	    publish_year: [Int]
    @NSManaged var 	    publisher: [String]
    @NSManaged var 	    seed: [String]
    @NSManaged var 	    subject: [String]
    @NSManaged var      subtitle: String
    @NSManaged var 	    text: [String]
    @NSManaged var 	    title_suggest: String
    @NSManaged var 	    title: String
    @NSManaged var 	    type: String
    
    @NSManaged var      sort_author_name: String
}
