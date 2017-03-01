//
//  OLWorkDetail.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/14/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

// import BNRCoreDataStack

let kWorksPrefix = "/works/"
let kWorkType    = "/type/work"

class OLWorkDetail: OLManagedObject {

    // MARK: Search Info
    struct SearchInfo {
        
        let objectID: NSManagedObjectID
        let key: String
    }
    
    static let entityName = "WorkDetail"
    
    var author_names: [String] {
        
         get {
            var names = [String]()
            
            for olid in self.authors {
                
                if let name = cachedAuthor( olid ) {
                    
                    names.append( name )
                }
            }
            return names
        }
    }

    fileprivate var ebook_item_cache = [OLEBookItem]()
    var ebook_items: [OLEBookItem] {
        
        get {
            if ebook_item_cache.isEmpty && mayHaveFullText {
                
                if let moc = self.managedObjectContext {
                    
                    let items: [OLEBookItem]? = OLEBookItem.findObject( key, entityName: OLEBookItem.entityName, keyFieldName: "workKey", moc: moc )
                    if let items = items , !items.isEmpty {
                        
                        ebook_item_cache = items
                        has_fulltext = 1
                    }
                }
            }
            
            return ebook_item_cache
        }
    }

    class func parseJSON( _ parentKey: String, index: Int, currentObjectID: NSManagedObjectID?, json: [String: AnyObject], moc: NSManagedObjectContext ) -> OLWorkDetail? {
        
        guard let parsed = ParsedFromJSON.fromJSON( json ) else { return nil }
            
        moc.mergePolicy = NSOverwriteMergePolicy
        
        var newObject: OLWorkDetail?
        
        if let currentObjectID = currentObjectID {
            
            do {
                newObject = try moc.existingObject( with: currentObjectID ) as? OLWorkDetail
            }
            catch {
                
            }
        }
        
        if nil == newObject {

            newObject =
                NSEntityDescription.insertNewObject(
                    forEntityName: OLWorkDetail.entityName, into: moc
                ) as? OLWorkDetail
        }
        
        if let newObject = newObject {
        
            if parentKey.hasPrefix( kAuthorsPrefix ) {
                newObject.author_key = parentKey
            }
            if newObject.author_key.isEmpty && !parsed.authors.isEmpty {
                newObject.author_key = parsed.authors[0]
            }
            
            if 0 <= index {
                newObject.index = Int64( index )
            }
            newObject.retrieval_date = Date()
            
            newObject.populateObject( parsed )
        }
        
        return newObject
    }
    
    override func awakeFromFetch() {
        
        super.awakeFromFetch()
        
        if let moc = self.managedObjectContext {
            
            let items: [OLEBookItem]? = OLEBookItem.findObject( key, entityName: OLEBookItem.entityName, keyFieldName: "workKey", moc: moc )
            if let items = items , !items.isEmpty {
                
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
    
    override var heading: String {
        
        return self.title
    }
    
    override var isProvisional: Bool {
        
        return self.is_provisional
    }
    
    override var hasImage: Bool {
        
        return 0 < self.covers.count && 0 < self.covers[0]
    }
    
    override var firstImageID: Int {
        
        return 0 >= self.covers.count ? 0 : self.covers[0]
    }
    
    override var imageType: String { return "b" }
    
    override func imageID( _ index: Int ) -> Int {
        
        return index >= self.covers.count ? 0 : self.covers[index]
    }
    
    override func localURL( _ size: String, index: Int = 0 ) -> URL {
        
        return super.localURL( self.covers[index], size: size )
    }
    
    override func populateObject(_ parsed: OpenLibraryObject) {
        
        if let parsed = parsed as? ParsedFromJSON {
            
            self.is_provisional = false
            self.provisional_date = nil

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
            deluxeData[0].append( DeluxeData( type: .subheading, caption: "Subtitle", value: self.subtitle ) )
        }
        
        if !author_names.isEmpty {
            
            let authorNames = author_names.joined( separator: ", " )
            deluxeData[0].append(
                DeluxeData(
                        type: .heading,
                        caption: "Author\(author_names.count > 1 ? "s" : "")",
                        value: authorNames
                    )
                )
        }
        
        if hasImage {

            let deluxeItem =
                DeluxeData(
                        type: .imageBook,
                        caption: String( firstImageID ),
                        value: localURL( "M" ).absoluteString,
                        extraValue: localURL( "L", index: 0 ).absoluteString
                    )
            
            deluxeData.append( [deluxeItem] )
            
        }
        
        if hasFullText {
            
            var newData = [DeluxeData]()
            
            for item in ebook_items {
                
                let deluxeItem =
                    DeluxeData(
                            type: "full access" == item.status ? .downloadBook : .borrowBook,
                            caption: "eBook",
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
            
            deluxeData.append( [DeluxeData( type: .block, caption: "First Published", value: self.first_publish_date )] )
        }
        
        if !self.work_description.isEmpty {
            
            let fancyOutput = convertMarkdownToAttributedString( markdown: self.work_description )
            
            deluxeData.append( [DeluxeData( type: .html, caption: "Description", value: fancyOutput )] )
        }
        
        if !self.first_sentence.isEmpty {
            
            let fancyOutput = convertMarkdownToAttributedString( markdown: self.first_sentence )
            
            deluxeData.append( [DeluxeData( type: .html, caption: "First Sentence", value: fancyOutput )] )
        }
        
        if !self.notes.isEmpty {
            
            let fancyOutput = convertMarkdownToAttributedString( markdown: self.notes )
            
            deluxeData.append( [DeluxeData( type: .html, caption: "Notes", value: fancyOutput )] )
        }
        
        if !self.subjects.isEmpty || !self.subject_people.isEmpty || !self.subject_places.isEmpty || !self.subject_times.isEmpty {
            
            var newData = [DeluxeData]()
            
            if !self.subjects.isEmpty {
                
                let subjects = self.subjects.joined( separator: ", " )
                newData.append(
                    DeluxeData(
                        type: .block,
                        caption: "Subjects",
                        value: subjects
                    )
                )
            }
            if !self.subject_people.isEmpty {
                
                let subjects = self.subject_people.joined( separator: ", " )
                newData.append(
                    DeluxeData(
                        type: .block,
                        caption: "Subject People",
                        value: subjects
                    )
                )
            }
            if !self.subject_places.isEmpty {
                
                let subjects = self.subject_places.joined( separator: ", " )
                newData.append(
                    DeluxeData(
                        type: .block,
                        caption: "Subject Places",
                        value: subjects
                    )
                )
            }
            if !subject_times.isEmpty {
                
                let subjects = self.subject_times.joined( separator: ", " )
                newData.append(
                    DeluxeData(
                        type: .block,
                        caption: "Subject Times",
                        value: subjects
                    )
                )
            }
            
            if 0 < newData.count {
                
                deluxeData.append( newData )
            }
        }
        
        if !self.links.isEmpty {
            
            var newData = [DeluxeData]()
            
            for link in self.links {
                
                if let title = link["title"], let url = link["url"] {
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
            
            for index in 1 ..< self.covers.count {
                
                if 0 < covers[index] {
                    
                    let deluxeItem =
                        DeluxeData(
                                type: .imageBook,
                                caption: String( covers[index] ),
                                value: localURL( "M", index: index ).absoluteString,
                                extraValue: localURL( "L", index: index ).absoluteString
                            )
                    
                    deluxeData.append( [deluxeItem] )
                }
            }
            
            if !newData.isEmpty {
                
                deluxeData.append( newData )
            }
        }
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        var newData = [DeluxeData]()
        
        if let created = created {

            newData.append(
                    DeluxeData(
                        type: .inline,
                        caption: "Created",
                        value: dateFormatter.string( from: created as Date )
                    )
                )
        }

        if let last_modified = last_modified {
            
            newData.append(
                DeluxeData(
                    type: .inline,
                    caption: "Modified",
                    value: dateFormatter.string( from: last_modified as Date )
                )
            )
        }
        
        newData.append(
            DeluxeData(type: .inline, caption: "Revision", value: String( revision ) )
        )
        
        newData.append(
            DeluxeData(type: .inline, caption: "Latest Revision", value: String( latest_revision ) )
        )
        
        newData.append(
            DeluxeData( type: .inline, caption: "Type", value: type )
        )
        
        newData.append(
            DeluxeData( type: .inline, caption: "OLID", value: key )
        )
        
        newData.append(
                DeluxeData(
                    type: .inline,
                    caption: "Retrieved",
                    value: dateFormatter.string( from: retrieval_date as Date )
                )
            )
        
        newData.append(
            DeluxeData(type: .inline, caption: "Data", value: isProvisional ? "Provisional" : "Actual" )
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
        let created: Date?
        let last_modified: Date?
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
        
        class func fromJSON( _ json: [String: AnyObject] ) -> ParsedFromJSON? {
            
            guard let key = json["key"] as? String , !key.isEmpty else { return nil }
            
            guard let title = json["title"] as? String , !title.isEmpty else { return nil }
            
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
            created: Date?,
            last_modified: Date?,
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

extension OLWorkDetail {
    
    class func saveProvisionalWork( _ parsed: OLGeneralSearchResult, moc: NSManagedObjectContext ) -> OLWorkDetail? {
        
        var newObject: OLWorkDetail?
        
        newObject = findObject( parsed.key, entityName: entityName, moc: moc )
        if nil == newObject {
            
            newObject =
                NSEntityDescription.insertNewObject(
                    forEntityName: OLWorkDetail.entityName, into: moc
                ) as? OLWorkDetail
            
            if let newObject = newObject {
             
                newObject.populateProvisional( parsed )
            }
        }
        
        return newObject
    }
    
    func populateProvisional( _ parsed: OLGeneralSearchResult ) {
        
        self.retrieval_date = Date()
        self.provisional_date = Date()
        self.is_provisional = true
        
        self.has_fulltext = parsed.has_fulltext ? 1 : 0
        self.ebook_count_i = parsed.ebook_count_i
        
        if parsed.key.hasPrefix( kWorksPrefix ) {
            self.key = parsed.key
        } else {
            self.key = kWorksPrefix + parsed.key
        }
        self.type = kWorkType
        
        self.authors = parsed.author_key
        self.author_key = parsed.author_key.first ?? ""
        
        self.title = parsed.title
        self.subtitle = parsed.subtitle
        if parsed.cover_i != 0 {
            self.covers = [Int( parsed.cover_i )]
        } else {
            self.covers = []
        }
        self.coversFound = !self.covers.isEmpty && 0 < self.covers[0]
        
        self.first_publish_date = ""
        self.subjects = parsed.subject
        
        self.dewey_number = []
        self.ebook_count_i = parsed.ebook_count_i
        
        self.first_sentence = ""
        self.lc_classifications = []
        self.links = [[:]]
        self.notes = ""
        self.original_languages = []
        self.other_titles = []
        self.subject_people = []
        self.subject_places = []
        self.subject_times = []
        
        self.translated_titles = []
        self.work_description = ""
    }

    class func saveProvisionalWork( _ parsed: OLGeneralSearchResult.ParsedFromJSON, moc: NSManagedObjectContext ) -> OLWorkDetail? {
        
        var newObject: OLWorkDetail?
        
        newObject = findObject( parsed.key, entityName: entityName, moc: moc )
        if nil == newObject {
            
            newObject =
                NSEntityDescription.insertNewObject(
                    forEntityName: OLWorkDetail.entityName, into: moc
                ) as? OLWorkDetail
            
            if let newObject = newObject {
                
                newObject.populateProvisional( parsed )
            }
        }
        
        return newObject
    }
    
    func populateProvisional( _ parsed: OLGeneralSearchResult.ParsedFromJSON ) {
        
        self.retrieval_date = Date()
        self.provisional_date = Date()
        self.is_provisional = true
        
        self.has_fulltext = parsed.has_fulltext ? 1 : 0
        self.ebook_count_i = parsed.ebook_count_i
        
        if parsed.key.hasPrefix( kWorksPrefix ) {
            self.key = parsed.key
        } else {
            self.key = kWorksPrefix + parsed.key
        }
        self.type = kWorkType
        
        self.authors = parsed.author_key
        self.author_key = parsed.author_key.first ?? ""
        
        self.title = parsed.title
        self.subtitle = parsed.subtitle
        if parsed.cover_i != 0 {
            self.covers = [Int( parsed.cover_i )]
        } else {
            self.covers = []
        }
        self.coversFound = !self.covers.isEmpty && 0 < self.covers[0]
        
        self.first_publish_date = ""
        self.subjects = parsed.subject
        
        self.dewey_number = []
        self.ebook_count_i = parsed.ebook_count_i
        self.edition_count = Int64( parsed.edition_key.count )
        
        self.first_sentence = ""
        self.lc_classifications = []
        self.links = [[:]]
        self.notes = ""
        self.original_languages = []
        self.other_titles = []
        self.subject_people = []
        self.subject_places = []
        self.subject_times = []
        
        self.translated_titles = []
        self.work_description = ""
    }
    
}

extension OLWorkDetail {
    
    class func buildFetchRequest() -> NSFetchRequest< OLWorkDetail > {
        
        return NSFetchRequest( entityName: OLWorkDetail.entityName )
    }
}

