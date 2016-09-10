//
//  OLWorkDetail.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/14/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import BNRCoreDataStack

let kWorksPrefix = "/works/"
let kWorkType    = "/type/work"

class OLWorkDetail: OLManagedObject, CoreDataModelable {

    // MARK: Search Info
    struct SearchInfo {
        
        let objectID: NSManagedObjectID
        let key: String
    }
    
    static let entityName = "WorkDetail"
    
    private var author_name_cache = [String]()
    var author_names: [String] {
        
         get {
            var names = author_name_cache
            
            if names.isEmpty {
            
                if let moc = self.managedObjectContext {

                    for olid in self.authors {
                        
                        if let author: OLAuthorDetail = OLWorkDetail.findObject( olid, entityName: OLAuthorDetail.entityName, moc: moc ) {
                            
                            author_name_cache.append( author.name )
                        }
                    }
                    
                    names = author_name_cache
                }
            }
            
            return names
        }
    }

    private var ebook_item_cache = [OLEBookItem]()
    var ebook_items: [OLEBookItem] {
        
        get {
            if ebook_item_cache.isEmpty && mayHaveFullText {
                
                if let moc = self.managedObjectContext {
                    
                    let items: [OLEBookItem]? = OLEBookItem.findObject( key, entityName: OLEBookItem.entityName, keyFieldName: "workKey", moc: moc )
                    if let items = items where !items.isEmpty {
                        
                        ebook_item_cache = items
                        has_fulltext = 1
                    }
                }
            }
            
            return ebook_item_cache
        }
    }

    class func parseJSON( parentKey: String, index: Int, json: [String: AnyObject], moc: NSManagedObjectContext ) -> OLWorkDetail? {
        
        guard let parsed = ParsedFromJSON.fromJSON( json ) else { return nil }
            
        var newObject: OLWorkDetail?
        
        newObject = findObject( parsed.key, entityName: entityName, moc: moc )
        if nil == newObject {
            
            newObject =
                NSEntityDescription.insertNewObjectForEntityForName(
                    OLWorkDetail.entityName, inManagedObjectContext: moc
                ) as? OLWorkDetail
            
        }
        
        if let newObject = newObject {
        
            if parentKey.hasPrefix( kAuthorsPrefix ) {
                newObject.author_key = parentKey
            }
            if newObject.author_key.isEmpty && !parsed.authors.isEmpty {
                newObject.author_key = parsed.authors[0]
            }
            
            newObject.index = Int64( index )
            newObject.retrieval_date = NSDate()
            newObject.provisional_date = nil
            
            newObject.populateObject( parsed )
        }
        
        return newObject
    }
    
    class func saveProvisionalWork( parsed: OLGeneralSearchResult.ParsedFromJSON, moc: NSManagedObjectContext ) -> OLWorkDetail? {
        
        var newObject: OLWorkDetail?

        newObject = findObject( parsed.key, entityName: entityName, moc: moc )
        if nil == newObject {
            
            newObject =
                NSEntityDescription.insertNewObjectForEntityForName(
                    OLWorkDetail.entityName, inManagedObjectContext: moc
                ) as? OLWorkDetail
            
            if let newObject = newObject {

                newObject.retrieval_date = NSDate()
                newObject.provisional_date = NSDate()
                
                newObject.has_fulltext = parsed.has_fulltext ? 1 : 0
                newObject.ebook_count_i = parsed.ebook_count_i
                
                if parsed.key.hasPrefix( kWorksPrefix ) {
                    newObject.key = parsed.key
                } else {
                    newObject.key = kWorksPrefix + parsed.key
                }
                newObject.type = kWorkType
                
                newObject.authors = parsed.author_key
                newObject.author_key = parsed.author_key.first ?? ""
                newObject.author_name_cache = parsed.author_name
                
                newObject.title = parsed.title
                if parsed.cover_i != 0 {
                    newObject.covers = [Int( parsed.cover_i )]
                } else {
                    newObject.covers = [Int]()
                }
                newObject.coversFound = !newObject.covers.isEmpty && 0 < newObject.covers[0]
                
                newObject.first_publish_date = String( parsed.first_publish_year )
                newObject.subjects = parsed.subject
            }
        }
        
        return newObject
    }
    
    override func awakeFromFetch() {
        
        super.awakeFromFetch()
        
        if let moc = self.managedObjectContext {
            
            for olid in self.authors {
                
                if let name = cachedAuthor( olid ) {
                    author_name_cache.append( name )
                }
            }

            let items: [OLEBookItem]? = OLEBookItem.findObject( key, entityName: OLEBookItem.entityName, keyFieldName: "workKey", moc: moc )
            if let items = items where !items.isEmpty {
                
                ebook_item_cache = items
                has_fulltext = 1
            }
        }
    }
    
    var mayHaveFullText: Bool {
        
        return 0 != self.has_fulltext
    }
    
    var hasFullText: Bool {
        
        return 1 == self.has_fulltext && self.ebook_count_i > 0 && !self.ebook_item_cache.isEmpty
    }
    
    func resetFulltext() -> Void {
        
        has_fulltext = -1
        ebook_item_cache = [OLEBookItem]()
        
    }
    
    func resetAuthors() -> Void {
        
        author_name_cache = [String]()
    }
    
    override var heading: String {
        
        return self.title
    }
    
    override var isProvisional: Bool {
        
        return nil != self.provisional_date
    }
    
    override var hasImage: Bool {
        
        return self.coversFound
    }
    
    override var firstImageID: Int {
        
        return 0 >= self.covers.count ? 0 : self.covers[0]
    }
    
    override var imageType: String { return "b" }
    
    override func imageID( index: Int ) -> Int {
        
        return index >= self.covers.count ? 0 : self.covers[index]
    }
    
    override func localURL( size: String, index: Int = 0 ) -> NSURL {
        
        return super.localURL( self.key, size: size, index: index )
    }
    
    override func populateObject(parsed: OpenLibraryObject) {
        
        if let parsed = parsed as? ParsedFromJSON {
            
            self.key = parsed.key
            self.created = parsed.created
            self.last_modified = parsed.last_modified
            self.revision = parsed.revision
            self.latest_revision = parsed.latest_revision
            self.type = parsed.type
            
            self.title = parsed.title
            self.subtitle = parsed.subtitle
            self.authors = parsed.authors
            self.translated_titles = parsed.translated_titles
            self.subjects = parsed.subjects
            self.subject_places = parsed.subject_places
            self.subject_times = parsed.subject_times
            self.subject_people = parsed.subject_people
            self.work_description = parsed.work_description
            self.dewey_number = parsed.dewey_number
            self.lc_classifications = parsed.lc_classifications
            self.first_sentence = parsed.first_sentence
            self.original_languages = parsed.original_languages
            self.other_titles = parsed.other_titles
            self.first_publish_date = parsed.first_publish_date
            self.links = parsed.links
            self.notes = parsed.notes
            // cover_edition of type /type/edition
            self.covers = parsed.covers
            self.coversFound = parsed.covers.count > 0 && 0 < parsed.covers[0]
            self.ebook_count_i = 0
        }
    }
    
    override func buildDeluxeData() -> [[DeluxeData]] {
        
        var deluxeData = [[DeluxeData]]()
        
        deluxeData.append( [DeluxeData( type: .heading, caption: "Title", value: self.title )] )
        if !subtitle.isEmpty {
            deluxeData[0].append( DeluxeData( type: .subheading, caption: "Subtitle:", value: self.subtitle ) )
        }
        
        if !author_names.isEmpty {
            
            let authorNames = author_names.joinWithSeparator( ", " )
            deluxeData[0].append(
                DeluxeData(
                        type: .heading,
                        caption: "Author\(author_names.count > 1 ? "s" : ""):",
                        value: authorNames
                    )
                )
        }
        
        if hasImage {
            
            let value = localURL( "M" ).absoluteString
            let extraValue = localURL( "L", index: 0 ).absoluteString
            let deluxeItem =
                DeluxeData(
                        type: .imageBook,
                        caption: String( firstImageID ),
                        value: value,
                        extraValue: extraValue
                    )
            
            deluxeData.append( [deluxeItem] )
            
        }
        
        if hasFullText {
            
            var newData = [DeluxeData]()
            
            for item in ebook_items {
                
                let deluxeItem =
                    DeluxeData(
                            type: "full access" == item.status ? .downloadBook : .borrowBook,
                            caption: "eBook:",
                            value: item.status,
                            extraValue: item.itemURL
                        )
                
                newData.append( deluxeItem )
            }
            
            if !newData.isEmpty {
                
                deluxeData.append( newData )
            }
        }
        
        if !self.first_publish_date.isEmpty {
            
            deluxeData.append( [DeluxeData( type: .inline, caption: "First Published:", value: self.first_publish_date )] )
        }
        
        if !self.work_description.isEmpty {
            
            let fancyOutput = fancyMarkdown.transform( self.work_description )
            
            deluxeData.append( [DeluxeData( type: .html, caption: "Description", value: fancyOutput )] )
        }
        
        if !self.first_sentence.isEmpty {
            
            let fancyOutput = fancyMarkdown.transform( self.first_sentence )
            
            deluxeData.append( [DeluxeData( type: .html, caption: "First Sentence", value: fancyOutput )] )
        }
        
        if !self.notes.isEmpty {
            
            let fancyOutput = fancyMarkdown.transform( self.notes )
            
            deluxeData.append( [DeluxeData( type: .html, caption: "Notes", value: fancyOutput )] )
        }
        
        if !self.links.isEmpty {
            
            var newData = [DeluxeData]()
            
            for link in self.links {
                
                if let title = link["title"], url = link["url"] {
                    newData.append( DeluxeData( type: .link, caption: title, value: url ) )
//                    print( "\(title) \(url)" )
                }
            }
            
            if 0 < newData.count {
                
                deluxeData.append( newData )
            }
        }
        
        if 1 < self.covers.count {
            
            let newData = [DeluxeData]()
            
            for index in 1..<self.covers.count {
                
                if -1 != covers[index] {
                    
                    let value = localURL( "M", index: index ).absoluteString
                    let extraValue = localURL( "L", index: index ).absoluteString
                    let deluxeItem =
                        DeluxeData(
                            type: .imageBook,
                            caption: String( covers[index] ),
                            value: value,
                            extraValue: extraValue
                    )
                    
                    deluxeData.append( [deluxeItem] )
                }
            }
            
            if !newData.isEmpty {
                
                deluxeData.append( newData )
            }
        }
        
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .MediumStyle
        
        var newData = [DeluxeData]()
        
        if let created = created {

            newData.append(
                    DeluxeData(
                        type: .inline,
                        caption: "Created:",
                        value: dateFormatter.stringFromDate( created )
                    )
                )
        }

        if let last_modified = last_modified {
            
            newData.append(
                DeluxeData(
                    type: .inline,
                    caption: "Last Modified:",
                    value: dateFormatter.stringFromDate( last_modified )
                )
            )
        }
        
        newData.append(
            DeluxeData(type: .inline, caption: "Revision:", value: String( revision ) )
        )
        
        newData.append(
            DeluxeData(type: .inline, caption: "Latest Revision:", value: String( latest_revision ) )
        )
        
        newData.append(
            DeluxeData( type: .inline, caption: "Type:", value: type )
        )
        
        newData.append(
            DeluxeData( type: .inline, caption: "OLID:", value: key )
        )
        
        newData.append(
                DeluxeData(
                    type: .inline,
                    caption: "Retrieved:",
                    value: dateFormatter.stringFromDate( retrieval_date )
                )
            )
        
        deluxeData.append( newData )

        return deluxeData
    }
}

extension OLWorkDetail {
    
    /// A struct to represent a parsed work
    class ParsedFromJSON: OpenLibraryObject {
        
        // MARK: Properties.
        let key: String
        let created: NSDate?
        let last_modified: NSDate?
        let revision: Int64
        let latest_revision: Int64
        let type: String
        
        let title: String                   // of type /type/string
        let subtitle: String                // of type /type/string
        let authors: [String]               // of type /type/author_role
        let translated_titles: [String]     // of type /type/translated_string
        let subjects: [String]              // of type /type/string
        let subject_places: [String]        // of type /type/string
        let subject_times: [String]         // of type /type/string
        let subject_people: [String]        // of type /type/string
        let work_description: String        // of type /type/text
        let dewey_number: [String]          // of type /type/string
        let lc_classifications: [String]    // of type /type/string
        let first_sentence: String          // of type /type/text
        let original_languages: [String]    // of type /type/language
        let other_titles: [String]          // of type /type/string
        let first_publish_date: String      // of type /type/string
        let links: [[String: String]]       // transformable
        let notes: String                   // of type /type/text
        // cover_edition of type /type/edition
        let covers: [Int]                   // of type /type/int
        
        // MARK: Initialization
        
        class func fromJSON( json: [String: AnyObject] ) -> ParsedFromJSON? {
            
            guard let key = json["key"] as? String where !key.isEmpty else { return nil }
            
            guard let title = json["title"] as? String where !title.isEmpty else { return nil }
            
            let subtitle = OpenLibraryObject.OLString( json["subtitle"] )
            
            // authors
            let authors = OpenLibraryObject.OLAuthorRole( json["authors"] )
            
            let translated_titles = OpenLibraryObject.OLStringArray( json["translated_titles"] )
            
            let subjects = OpenLibraryObject.OLStringArray( json["subjects"] )
            
            let subject_places = OpenLibraryObject.OLStringArray( json["subject_places"] )
            
            let subject_times = OpenLibraryObject.OLStringArray( json["subject_times"] )
            
            let subject_people = OpenLibraryObject.OLStringArray( json["subject_people"] )
            
            let work_description = OpenLibraryObject.OLText( json["description"] )
            
            let dewey_number = OpenLibraryObject.OLStringArray( json["dewey_number"] )
            
            let lc_classifications = OpenLibraryObject.OLStringArray( json["lc_classifications"] )
            
            let first_sentence = OpenLibraryObject.OLText( json["first_sentence"] )
            
            let original_languages = OpenLibraryObject.OLStringArray( json["original_languages"] )
            
            let other_titles = OpenLibraryObject.OLStringArray( json["other_titles"] )
            
            let first_publish_date = OpenLibraryObject.OLDateStamp( json["first_publish_date"] )
            
            let links = OpenLibraryObject.OLLinks( json )
            
            let notes = OpenLibraryObject.OLText( json["notes"] )
            
            let covers = OpenLibraryObject.OLIntArray( json["covers"] )
            
            var revision = Int64( 0 )
            if let r = json["revision"] as? Int64 {
                
                revision = r
            }
            
            var latest_revision = Int64( 0 )
            if let lr = json["latest_revision"] as? Int64 {
                
                latest_revision = lr
            }
            
            let created = OpenLibraryObject.OLTimeStamp( json["created"] )
            
            let last_modified = OpenLibraryObject.OLTimeStamp( json["last_modified"] )
            
            let type = OpenLibraryObject.OLKeyedValue( json["type"], key: "key" )
            
            return ParsedFromJSON( key: key, created: created, last_modified: last_modified, revision: revision, latest_revision: latest_revision, type: type, title: title, subtitle: subtitle, authors: authors, translated_titles: translated_titles, subjects: subjects, subject_places: subject_places, subject_times: subject_times, subject_people: subject_people, work_description: work_description, dewey_number: dewey_number, lc_classifications: lc_classifications, first_sentence: first_sentence, original_languages: original_languages, other_titles: other_titles, first_publish_date: first_publish_date, links: links, notes: notes, covers: covers )
        }
        
        init(
            key: String,
            created: NSDate?,
            last_modified: NSDate?,
            revision: Int64,
            latest_revision: Int64,
            type: String,
            
            title: String,
            subtitle: String,
            authors: [String],
            translated_titles: [String],
            subjects: [String],
            subject_places: [String],
            subject_times: [String],
            subject_people: [String],
            work_description: String,
            dewey_number: [String],
            lc_classifications: [String],
            first_sentence: String,
            original_languages: [String],
            other_titles: [String],
            first_publish_date: String,
            links: [[String: String]],
            notes: String,
            // cover_edition of type /type/edition
            covers: [Int]                   // of type /type/int
            ) {
            
            self.key = key
            self.created = created
            self.last_modified = last_modified
            self.revision = revision
            self.latest_revision = latest_revision
            self.type = type
            
            self.title = title
            self.subtitle = subtitle
            self.authors = authors
            self.translated_titles = translated_titles
            self.subjects = subjects
            self.subject_places = subject_places
            self.subject_times = subject_times
            self.subject_people = subject_people
            self.work_description = work_description
            self.dewey_number = dewey_number
            self.lc_classifications = lc_classifications
            self.first_sentence = first_sentence
            self.original_languages = original_languages
            self.other_titles = other_titles
            self.first_publish_date = first_publish_date
            self.links = links
            self.notes = notes
            // cover_edition of type /type/edition
            self.covers = covers
        }
    }
}
