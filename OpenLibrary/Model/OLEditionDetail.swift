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
    
    @NSManaged var author_key: String
    @NSManaged var work_key: String
    @NSManaged var index: Int64
    
    @NSManaged var key: String
    @NSManaged var created: NSDate?
    @NSManaged var last_modified: NSDate?
    @NSManaged var revision: Int64
    @NSManaged var latest_revision: Int64
    @NSManaged var type: String
    
    @NSManaged var accompanying_material: String
    @NSManaged var authors: [String]
    @NSManaged var by_statement: String
    @NSManaged var collections: [String]
    @NSManaged var contributions: [String]
    @NSManaged var copyright_date: String
    @NSManaged var covers: [Int]
    @NSManaged var coversFound: Bool
    @NSManaged var dewey_decimal_class: [String]
    @NSManaged var distributors: [String]
    @NSManaged var edition_description: String
    @NSManaged var edition_name: String
    @NSManaged var first_sentence: String
    @NSManaged var genres: [String]
    @NSManaged var isbn_10: [String]
    @NSManaged var isbn_13: [String]
    @NSManaged var languages: [String]
    @NSManaged var lc_classifications: [String]
    @NSManaged var lccn: [String]
    @NSManaged var location: [String]
    @NSManaged var notes: String
    @NSManaged var number_of_pages: Int64
    @NSManaged var ocaid: String
    @NSManaged var oclc_numbers: [String]
    @NSManaged var other_titles: [String]
    @NSManaged var pagination: String
    @NSManaged var physical_dimensions: String
    @NSManaged var physical_format: String
    @NSManaged var publish_country: String
    @NSManaged var publish_date: String
    @NSManaged var publish_places: [String]
    @NSManaged var publishers: [String]
    @NSManaged var scan_on_demand: Bool
    @NSManaged var series: [String]
    @NSManaged var source_records: [String]
    @NSManaged var subjects: [String]
    @NSManaged var subtitle: String
    @NSManaged var table_of_contents: [[String: String]]
    @NSManaged var title_prefix: String
    @NSManaged var title: String
    @NSManaged var translated_from: [String]
    @NSManaged var translation_of: String
    @NSManaged var uri_descriptions: [String]
    @NSManaged var uris: [String]
    @NSManaged var weight: String
    @NSManaged var work_titles: [String]
    @NSManaged var works: [String]
    //    scan_records[]: [String]
    //    volumes[]: [String]
    
//    var editionSearchInfo: SearchInfo {
//        
//        return SearchInfo( objectID: self.objectID, key: self.key )
//    }
//    
//    var authorSearchInfo: SearchInfo {
//        
//        return SearchInfo( objectID: self.objectID, key: self.author_key )
//    }
//
    override var hasImage: Bool {
        
        return 0 < self.covers.count
    }
    
    override var firstImageID: Int {
        
        return 0 >= self.covers.count ? 0 : self.covers[0]
    }
    
    override func localURL( size: String ) -> NSURL {
        
        return super.localURL( self.key, size: size )
    }
}
