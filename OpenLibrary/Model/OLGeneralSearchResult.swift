//
//  OLGeneralSearchResult.swift
//  
//
//  Created by Bob Wakefield on 4/19/16.
//
//

import Foundation
import CoreData

import BNRCoreDataStack

private class ParsedSearchResult: OpenLibraryObject {
    
    // MARK: Properties.
    
    var 	    author_key: [String]
    var 	    author_name: [String]
    var 	    cover_edition_key: String
    var 	    cover_i: Int64
    var 	    ebook_count_i: Int64
    var 	    edition_count: Int64
    var 	    edition_key: [String]
    var 	    first_publish_year: Int16
    var 	    first_sentence: [String]
    var 	    has_fulltext: Bool
    var 	    ia_collection_s: String
    var 	    ia: [String]
    var 	    id_goodreads: [String]
    var 	    id_librarything: [String]
    var 	    isbn: [String]
    var 	    key: String
    var 	    language: [String]
    var 	    last_modified_i: Int64
    var 	    lccn: [String]
    var 	    person: [String]
    var 	    printdisabled_s: String
    var 	    public_scan_b: Bool
    var 	    publish_date: [String]
    var 	    publish_place: [String]
    var 	    publish_year: [Int]
    var 	    publisher: [String]
    var 	    seed: [String]
    var 	    subject: [String]
    var 	    text: [String]
    var 	    title_suggest: String
    var 	    title: String
    var 	    type: String
    
    // MARK: Initialization
    
    init(
        author_key: [String],
        author_name: [String],
        cover_edition_key: String,
        cover_i: Int64,
        ebook_count_i: Int64,
        edition_count: Int64,
        edition_key: [String],
        first_publish_year: Int16,
        first_sentence: [String],
        has_fulltext: Bool,
        ia_collection_s: String,
        ia: [String],
        id_goodreads: [String],
        id_librarything: [String],
        isbn: [String],
        key: String,
        language: [String],
        last_modified_i: Int64,
        lccn: [String],
        person: [String],
        printdisabled_s: String,
        public_scan_b: Bool,
        publish_date: [String],
        publish_place: [String],
        publish_year: [Int],
        publisher: [String],
        seed: [String],
        subject: [String],
        text: [String],
        title_suggest: String,
        title: String,
        type: String
    ) {
        self.author_key = author_key
        self.author_name = author_name
        self.cover_edition_key = cover_edition_key
        self.cover_i = cover_i
        self.ebook_count_i = ebook_count_i
        self.edition_count = edition_count
        self.edition_key = edition_key
        self.first_publish_year = first_publish_year
        self.first_sentence = first_sentence
        self.has_fulltext = has_fulltext
        self.ia_collection_s = ia_collection_s
        self.ia = ia
        self.id_goodreads = id_goodreads
        self.id_librarything = id_librarything
        self.isbn = isbn
        self.key = key
        self.language = language
        self.last_modified_i = last_modified_i
        self.lccn = lccn
        self.person = person
        self.printdisabled_s = printdisabled_s
        self.public_scan_b = public_scan_b
        self.publish_date = publish_date
        self.publish_place = publish_place
        self.publish_year = publish_year
        self.publisher = publisher
        self.seed = seed
        self.subject = subject
        self.text = text
        self.title_suggest = title_suggest
        self.title = title
        self.type = type
    }
    
    convenience init?( match: [String: AnyObject] ) {
        
        guard let key = match["key"] as? String else { return nil }
        
        guard let type = match["type"] as? String else { return nil }
        
        let author_key         = match["author_key"] as? [String] ?? [String]()
        let author_name        = match["author_name"] as? [String] ?? [String]()
        let cover_edition_key  = match["cover_edition_key"] as? String ?? ""
        let cover_i            = match["cover_i"] as? Int64 ?? 0
        let ebook_count_i      = match["ebook_count_i"] as? Int64 ?? 0
        let edition_count      = match["edition_count"] as? Int64 ?? 0
        let edition_key        = match["edition_key"] as? [String] ?? [String]()
        let first_publish_year = match["first_publish_year"] as? Int16 ?? 0
        let first_sentence     = match["first_sentence"] as? [String] ?? [String]()
        let has_fulltext       = match["has_fulltext"] as? Bool ?? false
        let ia_collection_s    = match["ia_collection_s"] as? String ?? ""
        let ia                 = match["ia"] as? [String] ?? [String]()
        let id_goodreads       = match["id_goodreads"] as? [String] ?? [String]()
        let id_librarything    = match["id_librarything"] as? [String] ?? [String]()
        let isbn               = match["isbn"] as? [String] ?? [String]()

        let language           = match["language"] as? [String] ?? [String]()
        let last_modified_i    = match["last_modified_i"] as? Int64 ?? 0
        let lccn               = match["lccn"] as? [String] ?? [String]()
        let person             = match["person"] as? [String] ?? [String]()
        let printdisabled_s    = match["printdisabled_s"] as? String ?? ""
        let public_scan_b      = match["public_scan_b"] as? Bool ?? false
        let publish_date       = match["publish_date"] as? [String] ?? [String]()
        let publish_place      = match["publish_place"] as? [String] ?? [String]()
        let publish_year       = match["publish_year"] as? [Int] ?? [Int]()
        let publisher          = match["publisher"] as? [String] ?? [String]()
        let seed               = match["seed"] as? [String] ?? [String]()
        let subject            = match["subject"] as? [String] ?? [String]()
        let text               = match["text"] as? [String] ?? [String]()
        let title_suggest      = match["title_suggest"] as? String ?? ""
        let title              = match["title"] as? String ?? ""
        
        self.init(
            author_key: author_key,
            author_name: author_name,
            cover_edition_key: cover_edition_key,
            cover_i: cover_i,
            ebook_count_i: ebook_count_i,
            edition_count: edition_count,
            edition_key: edition_key,
            first_publish_year: first_publish_year,
            first_sentence: first_sentence,
            has_fulltext: has_fulltext,
            ia_collection_s: ia_collection_s,
            ia: ia,
            id_goodreads: id_goodreads,
            id_librarything: id_librarything,
            isbn: isbn,
            key: key,
            language: language,
            last_modified_i: last_modified_i,
            lccn: lccn,
            person: person,
            printdisabled_s: printdisabled_s,
            public_scan_b: public_scan_b,
            publish_date: publish_date,
            publish_place: publish_place,
            publish_year: publish_year,
            publisher: publisher,
            seed: seed,
            subject: subject,
            text: text,
            title_suggest: title_suggest,
            title: title,
            type: type
        )
        
    }
}


class OLGeneralSearchResult: OLManagedObject, CoreDataModelable {

    // Insert code here to add functionality to your managed object subclass
    static let entityName = "GeneralSearchResult"
    
    class func parseJSON(sequence: Int64, index: Int64, match: [String: AnyObject], moc: NSManagedObjectContext ) -> OLGeneralSearchResult? {
        
        guard let parsed = ParsedSearchResult( match: match ) else { return nil }
        
        guard let newObject =
            NSEntityDescription.insertNewObjectForEntityForName(
                OLGeneralSearchResult.entityName, inManagedObjectContext: moc
                ) as? OLGeneralSearchResult else { return nil }
        
        newObject.sequence = sequence
        newObject.index = index
        
        newObject.author_key = parsed.author_key
        newObject.author_name = parsed.author_name
        newObject.cover_edition_key = parsed.cover_edition_key
        newObject.cover_i = parsed.cover_i
        newObject.ebook_count_i = parsed.ebook_count_i
        newObject.edition_count = parsed.edition_count
        newObject.edition_key = parsed.edition_key
        newObject.first_publish_year = parsed.first_publish_year
        newObject.first_sentence = parsed.first_sentence
        newObject.has_fulltext = parsed.has_fulltext
        newObject.ia_collection_s = parsed.ia_collection_s
        newObject.ia = parsed.ia
        newObject.id_goodreads = parsed.id_goodreads
        newObject.id_librarything = parsed.id_librarything
        newObject.isbn = parsed.isbn
        newObject.key = parsed.key
        newObject.language = parsed.language
        newObject.last_modified_i = parsed.last_modified_i
        newObject.lccn = parsed.lccn
        newObject.person = parsed.person
        newObject.printdisabled_s = parsed.printdisabled_s
        newObject.public_scan_b = parsed.public_scan_b
        newObject.publish_date = parsed.publish_date
        newObject.publish_place = parsed.publish_place
        newObject.publish_year = parsed.publish_year
        newObject.publisher = parsed.publisher
        newObject.seed = parsed.seed
        newObject.subject = parsed.subject
        newObject.text = parsed.text
        newObject.title_suggest = parsed.title_suggest
        newObject.title = parsed.title
        newObject.type = parsed.type
        
        return newObject
    }
    
    override var hasImage: Bool { return 0 != cover_i }
    override var firstImageID: Int { return Int( cover_i ) }
    
    override func localURL( size: String, index: Int = 0 ) -> NSURL {

        return super.localURL( self.key, size: size, index: index )
    }

}
