//
//  OLTitleSearchResult.swift
//  OpenLibraryBrowser
//
//  Created by Bob Wakefield on 4/9/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import BNRCoreDataStack

private class ParsedSearchResult: OpenLibraryObject {
    
    // MARK: Properties.
    
    let key: String

    let author_key: [String]
    let author_name: [String]
    let contributor: [String]
    let cover_i: Int64
    let first_publish_year: String
    let has_fulltext: Bool
    var subtitle: String
    let title: String
    let title_suggest: String
    

    // MARK: Initialization
    
    init(
        key: String,
        author_key: [String],
        author_name: [String],
        contributor: [String],
        cover_i: Int64,
        first_publish_year: String,
        has_fulltext: Bool,
        subtitle: String,
        title: String,
        title_suggest: String
        ) {
        self.key = key

        self.author_key = author_key
        self.author_name = author_name
        self.contributor = contributor
        self.cover_i = cover_i
        self.first_publish_year = first_publish_year
        self.has_fulltext = has_fulltext
        self.subtitle = subtitle
        self.title = title
        self.title_suggest = title_suggest
    }
    
    convenience init?( match: [String: AnyObject] ) {
        
        guard let key = match["key"] as? String else { return nil }
        
        guard let title = match["title"] as? String else { return nil }
        
        guard let title_suggest = match["title_suggest"] as? String else { return nil }
        
        let author_key = match["author_key"] as? [String] ?? [String]()
        let author_name = match["author_name"] as? [String] ?? [String]()
        let contributor = match["contributor"] as? [String] ?? [String]()
        let cover_i = match["cover_i"] as? Int ?? 0
        let first_publish_year_val = match["first_publish_year"] as? Int ?? 0
        var first_publish_year = ""
        if 0 != first_publish_year_val {
            
            first_publish_year = String( first_publish_year_val )
        }
        let has_fulltext = match["has_fulltext"] as? Bool ?? false
        let subtitle = match["subtitle"] as? String ?? ""
        
        self.init(
                key: key,
                author_key: author_key,
                author_name: author_name,
                contributor: contributor,
                cover_i: Int64( cover_i ),
                first_publish_year: first_publish_year,
                has_fulltext: has_fulltext,
                subtitle: subtitle,
                title: title,
                title_suggest: title_suggest
            )
        
    }
}

class OLTitleSearchResult: OLManagedObject, CoreDataModelable {
    
    // MARK: Search Info
    struct SearchInfo {
        let objectID: NSManagedObjectID
        let key: String
    }
    
    // MARK: Static Properties
    
    static let entityName = "TitleSearchResult"
    
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
    
    class func parseJSON(sequence: Int64, index: Int64, match: [String: AnyObject], moc: NSManagedObjectContext ) -> OLTitleSearchResult? {
        
        guard let parsed = ParsedSearchResult( match: match ) else { return nil }
        
        guard let newObject =
            NSEntityDescription.insertNewObjectForEntityForName(
                OLTitleSearchResult.entityName, inManagedObjectContext: moc
                ) as? OLTitleSearchResult else { return nil }
        
        newObject.sequence = sequence
        newObject.index = index
        
        newObject.key = parsed.key
        
        newObject.author_key = parsed.author_key
        newObject.author_name = parsed.author_name
        newObject.contributor = parsed.contributor
        newObject.cover_i = parsed.cover_i
        newObject.first_publish_year = parsed.first_publish_year
        newObject.has_fulltext = parsed.has_fulltext
        newObject.subtitle = parsed.subtitle
        newObject.title = parsed.title
        newObject.title_suggest = parsed.title_suggest
        
        return newObject
    }

    var searchInfo: SearchInfo {
        
        return SearchInfo( objectID: self.objectID, key: self.key )
    }
    
    override var hasImage: Bool { return 0 != cover_i }
    override var firstImageID: Int { return Int( cover_i ) }
    
    override func localURL( size: String ) -> NSURL {
        
        let key = self.key
        return super.localURL( key, size: size )
    }
}
