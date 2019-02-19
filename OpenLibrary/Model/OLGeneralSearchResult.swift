//
//  OLGeneralSearchResult.swift
//  
//
//  Created by Bob Wakefield on 4/19/16.
//
//

import Foundation
import CoreData

//import BNRCoreDataStack

class OLGeneralSearchResult: OLManagedObject {

    static let entityName = "GeneralSearchResult"

    // Insert code here to add functionality to your managed object subclass
    var language_names: [String] {
        
        var names = [String]()
        for code in language {
            
            if let name = findLanguage( forKey: "/languages/" + code ) {
                
                names.append( name )
            }
        }
        
        return names.sorted()
    }
    
    class func parseJSON(_ sequence: Int64, index: Int64, json: [String: AnyObject], moc: NSManagedObjectContext ) -> OLGeneralSearchResult? {
        
        guard let parsed = ParsedFromJSON( json: json ) else { return nil }
        
        var newObject: OLGeneralSearchResult?
        
        newObject = findObject( parsed.key, entityName: entityName, moc: moc )
        if nil == newObject {
            
            newObject =
                NSEntityDescription.insertNewObject(
                    forEntityName: OLGeneralSearchResult.entityName, into: moc
                ) as? OLGeneralSearchResult
            
        }
        
        if let newObject = newObject {
            
            newObject.sequence = sequence
            newObject.index = index
            
            newObject.retrieval_date = Date()
            
            newObject.populateObject( parsed )
            
            assert( parsed.author_key.count == parsed.author_name.count )
            for index in 0 ..< min( parsed.author_key.count, parsed.author_name.count ) {
                
                OLManagedObject.addAuthorToCache(
                        parsed.author_key[index], authorName: parsed.author_name[index]
                    )
            }
            
//            if let workDetail = OLGeneralSearchResult.saveProvisionalObjects( parsed, moc: moc ) {
//                
//                newObject.work_detail = workDetail
//            }
        }

        return newObject
    }
    
    override var hasImage: Bool { return 0 < cover_i }
    override var firstImageID: Int { return Int( cover_i ) }
    
    override var imageType: String { return "b" }
    
    override func localURL( _ size: String, index: Int = 0 ) -> URL {

        return super.localURL( firstImageID, size: size )
    }
    
    func populateObject( _ parsed: OLGeneralSearchResult.ParsedFromJSON ) {
        
        self.author_key = parsed.author_key
        self.author_name = parsed.author_name
        self.cover_edition_key = parsed.cover_edition_key
        self.cover_i = parsed.cover_i
        self.ebook_count_i = parsed.ebook_count_i
        self.edition_count = parsed.edition_count
        self.edition_key = parsed.edition_key
        self.first_publish_year = 0 == parsed.first_publish_year ? "Not entered" : "\(parsed.first_publish_year)"
        self.first_sentence = parsed.first_sentence
        self.has_fulltext = parsed.has_fulltext
        self.ia_collection_s = parsed.ia_collection_s
        self.ia = parsed.ia
        self.id_goodreads = parsed.id_goodreads
        self.id_librarything = parsed.id_librarything
        self.isbn = parsed.isbn
        self.key = parsed.key
        self.language = parsed.language
        self.last_modified_i = parsed.last_modified_i
        self.lccn = parsed.lccn
        self.person = parsed.person
        self.printdisabled_s = parsed.printdisabled_s
        self.public_scan_b = parsed.public_scan_b
        self.publish_date = parsed.publish_date
        self.publish_place = parsed.publish_place
        self.publish_year = parsed.publish_year
        self.publisher = parsed.publisher
        self.seed = parsed.seed
        self.subject = parsed.subject
        self.subtitle = parsed.subtitle
        self.text = parsed.text
        self.title_suggest = parsed.title_suggest
        self.title = parsed.title
        self.type = parsed.type
        
        self.sort_author_name = parsed.author_name.isEmpty ? "" : parsed.author_name[0]
    }
}

extension OLGeneralSearchResult {
    
    class ParsedFromJSON: OpenLibraryObject {
        
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
        var         subtitle: String
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
            subtitle: String,
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
            self.subtitle = subtitle
            self.text = text
            self.title_suggest = title_suggest
            self.title = title
            self.type = type
        }
        
        convenience init?( json: [String: AnyObject] ) {
            
            guard let key = json["key"] as? String else { return nil }
            
            guard let type = json["type"] as? String else { return nil }
            
            let tempAuthorKey = json["author_key"] as? [String] ?? [String]()
            var author_key = [String]()
            for authorKey in tempAuthorKey {
                
                if authorKey.hasPrefix( kAuthorsPrefix ) {
                    
                    author_key.append( authorKey )
                    
                } else {
                    
                    author_key.append( kAuthorsPrefix + authorKey )
                }
            }

            let author_name        = json["author_name"] as? [String] ?? [String]()
            let cover_edition_key  = json["cover_edition_key"] as? String ?? ""
            let cover_i            = json["cover_i"] as? Int ?? 0
            let ebook_count_i      = json["ebook_count_i"] as? Int ?? 0
            let edition_count      = json["edition_count"] as? Int ?? 0

            let tempEditionKey     = json["edition_key"] as? [String] ?? [String]()
            var edition_key = [String]()
            for editionKey in tempEditionKey {
                
                if editionKey.hasPrefix( kEditionsPrefix ) {
                    
                    edition_key.append( editionKey )
                    
                } else {
                    
                    edition_key.append( kEditionsPrefix + editionKey )
                }
            }
            
            let first_publish_year = json["first_publish_year"] as? Int ?? 0
            let first_sentence     = json["first_sentence"] as? [String] ?? [String]()
            let has_fulltext       = json["has_fulltext"] as? Bool ?? false
            let ia_collection_s    = json["ia_collection_s"] as? String ?? ""
            let ia                 = json["ia"] as? [String] ?? [String]()
            let id_goodreads       = json["id_goodreads"] as? [String] ?? [String]()
            let id_librarything    = json["id_librarything"] as? [String] ?? [String]()
            let isbn               = json["isbn"] as? [String] ?? [String]()
            
            let language           = json["language"] as? [String] ?? [String]()
            let last_modified_i    = json["last_modified_i"] as? Int64 ?? 0
            let lccn               = json["lccn"] as? [String] ?? [String]()
            let person             = json["person"] as? [String] ?? [String]()
            let printdisabled_s    = json["printdisabled_s"] as? String ?? ""
            let public_scan_b      = json["public_scan_b"] as? Bool ?? false
            let publish_date       = json["publish_date"] as? [String] ?? [String]()
            let publish_place      = json["publish_place"] as? [String] ?? [String]()
            let publish_year       = json["publish_year"] as? [Int] ?? [Int]()
            let publisher          = json["publisher"] as? [String] ?? [String]()
            let seed               = json["seed"] as? [String] ?? [String]()
            let subject            = json["subject"] as? [String] ?? [String]()
            let subtitle           = json["subtitle"] as? String ?? ""
            let text               = json["text"] as? [String] ?? [String]()
            let title_suggest      = json["title_suggest"] as? String ?? ""
            let title              = json["title"] as? String ?? ""
            
            self.init(
                author_key: author_key,
                author_name: author_name,
                cover_edition_key: cover_edition_key,
                cover_i: Int64( cover_i ),
                ebook_count_i: Int64( ebook_count_i ),
                edition_count: Int64( edition_count ),
                edition_key: edition_key,
                first_publish_year: Int16( first_publish_year ),
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
                subtitle: subtitle,
                text: text,
                title_suggest: title_suggest,
                title: title,
                type: type
            )
        }
    }
}

extension OLGeneralSearchResult {
    
    func saveProvisionalObjects() -> OLWorkDetail? {
        
        guard nil == self.work_detail else { return self.work_detail }
        
        guard let moc = self.managedObjectContext else { return nil }
        
        let workDetail = OLWorkDetail.saveProvisionalWork( self, moc: moc )
        if let workDetail = workDetail {
            
            self.work_detail = workDetail
            
            // save provisional authors
            for authorIndex in 0 ..< min( self.author_key.count, self.author_name.count ) {
                
                _ = OLAuthorDetail.saveProvisionalAuthor( authorIndex, parsed: self, moc: moc )
            }

            // do not save provisional editions
            
        }
        
        return workDetail
    }

}

extension OLGeneralSearchResult {
    
    class func buildFetchRequest() -> NSFetchRequest< OLGeneralSearchResult > {
        
        return NSFetchRequest( entityName: OLGeneralSearchResult.entityName )
    }
    
}
