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

    @NSManaged var title_suggest: String?
    @NSManaged var edition_key: NSObject?
    @NSManaged var cover_i: NSNumber?
    @NSManaged var isbn: NSObject?
    @NSManaged var has_fulltext: NSNumber?
    @NSManaged var text: NSObject?
    @NSManaged var author_name: NSObject?
    @NSManaged var seed: NSObject?
    @NSManaged var ia: NSObject?
    @NSManaged var author_key: NSObject?
    @NSManaged var subject: NSObject?
    @NSManaged var title: String?
    @NSManaged var ia_collection_s: String?
    @NSManaged var first_publish_year: NSNumber?
    @NSManaged var type: String?
    @NSManaged var ebook_count_i: NSNumber?
    @NSManaged var publish_place: NSObject?
    @NSManaged var printdisabled_s: String?
    @NSManaged var edition_count: NSNumber?
    @NSManaged var key: String?
    @NSManaged var id_goodreads: NSObject?
    @NSManaged var public_scan_b: NSNumber?
    @NSManaged var publisher: NSObject?
    @NSManaged var language: NSObject?
    @NSManaged var lccn: NSObject?
    @NSManaged var last_modified_i: NSNumber?
    @NSManaged var id_librarything: NSObject?
    @NSManaged var cover_edition_key: String?
    @NSManaged var first_sentence: NSObject?
    @NSManaged var person: NSObject?
    @NSManaged var publish_year: NSObject?
    @NSManaged var publish_date: NSObject?

}
