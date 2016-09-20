//
//  EditionDetail.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/16/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import BNRCoreDataStack

let kEditionsPrefix = "/books/"
let kEditionType = "/type/edition"

class OLEditionDetail: OLManagedObject, CoreDataModelable {

    private var author_name_cache = [String]()
    var author_names: [String] {
        
        get {
            
            if author_name_cache.isEmpty {
                
                for olid in self.authors {
                    
                    if let name = cachedAuthor( olid ) {
                        author_name_cache.append( name )
                    }
                }
            }
            
            return author_name_cache
        }
    }
    
    private func setLanguageNames() {
        
        for code in self.languages {
            
            if let name = OLManagedObject.languageLookup[code] {
                
                language_names.append( name )
            }
        }
    }
    
    private var ebook_item_cache = [OLEBookItem]()
    var ebook_items: [OLEBookItem] {
        
        get {
            if ebook_item_cache.isEmpty && mayHaveFullText {
                
                if let moc = self.managedObjectContext {
                    
                    let items: [OLEBookItem]? = OLEBookItem.findObject( work_key, entityName: OLEBookItem.entityName, keyFieldName: "workKey", moc: moc )
                    if let items = items where !items.isEmpty {
                        
                        ebook_item_cache = items
                        has_fulltext = 1
                    }
                }
            }
            
            return ebook_item_cache
        }
    }
    
    // MARK: Search Info
    struct SearchInfo {
        
        let objectID: NSManagedObjectID
        let key: String
    }
    
    static let entityName = "EditionDetail"
    
    class func parseJSON( authorKey: String, workKey: String, index: Int, json: [String: AnyObject], moc: NSManagedObjectContext ) -> OLEditionDetail? {

        guard let parsed = ParsedFromJSON.fromJSON( json ) else { return nil }
        
        var newObject: OLEditionDetail?
        
        newObject = findObject( parsed.key, entityName: entityName, moc: moc )
        if nil == newObject {
            
            newObject =
                NSEntityDescription.insertNewObjectForEntityForName(
                    OLEditionDetail.entityName, inManagedObjectContext: moc
                    ) as? OLEditionDetail
            
        }
        
        if let newObject = newObject {
        
            if !workKey.isEmpty {
                newObject.work_key = workKey
            } else {
                newObject.work_key = parsed.works.isEmpty ? "" : parsed.works[0]
            }
            if !authorKey.isEmpty {
                newObject.author_key = authorKey
            } else {
                newObject.author_key = parsed.authors.isEmpty ? "" : parsed.authors[0]
            }

            if !newObject.isProvisional {
                newObject.index = Int64( index )
            }
            newObject.retrieval_date = NSDate()
            newObject.provisional_date = nil
            
            newObject.populateObject( parsed )
            
            newObject.setLanguageNames()
        }

        return newObject
    }
    
    // create or update an editionDetail object with information from the ebook data

    class func saveProvisionalEdition( parsed parsed: OLEBookItem.ParsedFromJSON, moc: NSManagedObjectContext )  -> OLEditionDetail? {

        var newObject: OLEditionDetail?

        newObject = findObject( parsed.editionKey, entityName: entityName, moc: moc )
        if nil == newObject {

            newObject =
                NSEntityDescription.insertNewObjectForEntityForName(
                    OLEditionDetail.entityName, inManagedObjectContext: moc
                ) as? OLEditionDetail
        }

        if let newObject = newObject {
            
            newObject.retrieval_date = NSDate()
            newObject.provisional_date = NSDate()
            
            newObject.has_fulltext = 1
            
            newObject.key = parsed.editionKey
            newObject.type = "/type/edition"
            
            newObject.work_key = parsed.workKey
            
            newObject.authors = parsed.author_keys
            newObject.author_key = parsed.author_keys.first ?? ""
            newObject.author_name_cache = parsed.author_names
            
            newObject.title = parsed.title
            newObject.subtitle = parsed.subtitle
            
            if parsed.cover_id > 0 && 0 == newObject.covers.count {
                newObject.covers = [Int( parsed.cover_id )]
            } else {
                newObject.covers = [Int]()
            }
            newObject.coversFound = !newObject.covers.isEmpty && 0 < newObject.covers[0]
            
            newObject.languages = parsed.languages
            
            newObject.publish_date = parsed.publish_date
            
            newObject.isbn_10 = parsed.isbn_10
        }
        
        return newObject
    }

    class func saveProvisionalEdition( editionIndex: Int, parsed: OLGeneralSearchResult.ParsedFromJSON, moc: NSManagedObjectContext ) -> OLEditionDetail? {
        
        var newObject: OLEditionDetail?
        
        if editionIndex < parsed.edition_key.count {
 
            newObject = findObject( parsed.edition_key[editionIndex], entityName: entityName, moc: moc )
            if nil == newObject {
                
                newObject =
                    NSEntityDescription.insertNewObjectForEntityForName(
                        OLEditionDetail.entityName, inManagedObjectContext: moc
                    ) as? OLEditionDetail
                
                if let newObject = newObject {
                    
                    newObject.retrieval_date = NSDate()
                    newObject.provisional_date = NSDate()
                    
                    newObject.has_fulltext = parsed.has_fulltext ? 1 : 0
                    
                    newObject.key = parsed.edition_key[editionIndex]
                    newObject.type = "/type/edition"
                    
                    newObject.work_key = parsed.key
                    
                    newObject.authors = parsed.author_key
                    newObject.author_key = parsed.author_key.first ?? ""
                    newObject.author_name_cache = parsed.author_name
                    
                    newObject.title = parsed.title
                    if parsed.cover_i > 0 && newObject.key == parsed.cover_edition_key {
                        newObject.covers = [Int( parsed.cover_i )]
                    } else {
                        newObject.covers = [Int]()
                    }
                    newObject.coversFound = !newObject.covers.isEmpty && 0 < newObject.covers[0]
                    
                    newObject.languages = [String]()
                    
                    if editionIndex < parsed.publish_date.count {

                        newObject.publish_date = parsed.publish_date[editionIndex]

                    } else {
                        
                        newObject.publish_date = ""
                    }
                    newObject.subjects = parsed.subject
                    
                    
                }
            }
        }
        
        return newObject
    }
    
    override func awakeFromFetch() {
        
        super.awakeFromFetch()
        
        if let moc = self.managedObjectContext {
            
            for olid in self.authors {
                
                if let author: OLAuthorDetail = OLWorkDetail.findObject( olid, entityName: OLAuthorDetail.entityName, moc: moc ) {
                    
                    author_name_cache.append( author.name )
                }
            }

            let items: [OLEBookItem]? = OLEBookItem.findObject( work_key, entityName: OLEBookItem.entityName, keyFieldName: "workKey", moc: moc )
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
        
        return 1 == self.has_fulltext && !self.ebook_item_cache.isEmpty
    }
    
    func resetFulltext() -> Void {
        
        has_fulltext = -1
        ebook_item_cache = [OLEBookItem]()
        
    }
    
    override var heading: String {
        
        return self.title
    }
    
    override var subheading: String {
        
        return self.subtitle
    }
    
    override var defaultImageName: String {
        
        return "961-book-32.png"
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

    override func populateObject( parsed: OpenLibraryObject ) {
        
        self.retrieval_date = NSDate()
        
        if let parsed = parsed as? ParsedFromJSON {
            
            self.key = parsed.key
            self.created = parsed.created
            self.last_modified = parsed.last_modified
            self.revision = parsed.revision
            self.latest_revision = parsed.latest_revision
            self.type = parsed.type
            
            self.accompanying_material = parsed.accompanying_material
            self.authors = parsed.authors
            self.by_statement = parsed.by_statement
            self.collections = parsed.collections
            self.contributions = parsed.contributions
            self.copyright_date = parsed.copyright_date
            self.covers = parsed.covers
            self.coversFound = parsed.covers.count > 0 && 0 < parsed.covers[0]
            self.dewey_decimal_class = parsed.dewey_decimal_class
            self.distributors = parsed.distributors
            self.edition_description = parsed.edition_description
            self.edition_name = parsed.edition_name
            self.first_sentence = parsed.first_sentence
            self.genres = parsed.genres
            self.isbn_10 = parsed.isbn_10
            self.isbn_13 = parsed.isbn_13
            self.languages = parsed.languages
            self.lc_classifications = parsed.lc_classifications
            self.lccn = parsed.lccn
            self.location = parsed.location
            self.notes = parsed.notes
            self.number_of_pages = parsed.number_of_pages
            self.ocaid = parsed.ocaid
            self.oclc_numbers = parsed.oclc_numbers
            self.other_titles = parsed.other_titles
            self.pagination = parsed.pagination
            self.physical_dimensions = parsed.physical_dimensions
            self.physical_format = parsed.physical_format
            self.publish_country = parsed.publish_country
            self.publish_date = parsed.publish_date
            self.publish_places = parsed.publish_places
            self.publishers = parsed.publishers
            self.scan_on_demand = parsed.scan_on_demand
            self.series = parsed.series
            self.source_records = parsed.source_records
            self.subjects = parsed.subjects
            self.subtitle = parsed.subtitle
            self.table_of_contents = parsed.table_of_contents
            self.title = parsed.title
            self.title_prefix = parsed.title_prefix
            self.translated_from = parsed.translated_from
            self.translation_of = parsed.translation_of
            self.uri_descriptions = parsed.uri_descriptions
            self.uris = parsed.uris
            self.weight = parsed.weight
            self.work_titles = parsed.work_titles
            self.works = parsed.works
            //    self.scan_records[] = parsed.AnyObject
            //    self.volumes[] = parsed.AnyObject
        }
    }
    
    func findEBookItem() -> OLEBookItem? {
        
        var foundItem: OLEBookItem?
        
        print( "Edition OLID: \(key) \(ocaid)" )
        if mayHaveFullText && !ebook_items.isEmpty {
            
            for item in ebook_items {
                
                print( "\(item.editionKey) \(item.fromRecord) \(item.eBookKey)" )
                if item.editionKey == key {
                    
                    foundItem = item
                    break
                }
            }
        }

        return foundItem
    }
    
    // MARK: Deluxe Detail
    override func buildDeluxeData() -> [[DeluxeData]] {
        
        var deluxeData = [[DeluxeData]]()
        
        deluxeData.append( [DeluxeData( type: .heading, caption: "Title", value: self.title )] )
        if !subtitle.isEmpty {
            deluxeData[0].append( DeluxeData( type: .subheading, caption: "Subtitle:", value: self.subtitle ) )
        }
        
        if !by_statement.isEmpty {

            deluxeData[0].append(
                    DeluxeData( type: .heading, caption: "By Statement:", value: self.by_statement )
                )

        } else {

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
        
        if mayHaveFullText && !ebook_items.isEmpty {
            
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
        
        var newData = [DeluxeData]()
        if !self.publishers.isEmpty {
            
            let display = publishers.joinWithSeparator( ", " )
            newData.append( DeluxeData( type: .body, caption: "Publishers:", value: display ) )
        }
        
        if !self.publish_date.isEmpty {
            
            newData.append( DeluxeData( type: .inline, caption: "Published:", value: self.publish_date ) )
        }
        
        if !self.copyright_date.isEmpty {
            
            newData.append( DeluxeData( type: .inline, caption: "Copyright:", value: self.copyright_date ) )
        }
        
        if !language_names.isEmpty {
            
            let languageNames = language_names.joinWithSeparator( ", " )
            newData.append(
                DeluxeData(
                    type: .inline,
                    caption: "Language\(author_names.count > 1 ? "s" : ""):",
                    value: languageNames
                )
            )
        }
        
        if !newData.isEmpty {
            deluxeData.append( newData )
        }
        
        newData = [DeluxeData]()
        if !self.physical_format.isEmpty {
            
            newData.append( DeluxeData( type: .inline, caption: "Format:", value: self.physical_format ) )
        }
        
        if number_of_pages > 0 {
            
            newData.append( DeluxeData( type: .inline, caption: "Pages: ", value: "\(number_of_pages)" ) )
        }
        else if !self.pagination.isEmpty {
            
            newData.append( DeluxeData( type: .body, caption: "", value: self.pagination ) )
        }
        
        if !self.physical_dimensions.isEmpty {
            
            newData.append( DeluxeData( type: .inline, caption: "Dimensions:", value: self.physical_dimensions ) )
        }
        
        if !self.weight.isEmpty {
            
            newData.append( DeluxeData( type: .inline, caption: "Weight:", value: self.weight ) )
        }
        
        if !newData.isEmpty {

            deluxeData.append( newData )
        }

        if !self.edition_description.isEmpty {
            
            let fancyOutput = fancyMarkdown.transform( self.edition_description )
            
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
        
        if !self.uris.isEmpty && self.uris.count == self.uri_descriptions.count {
            
            var newData = [DeluxeData]()
            
            for link in 0 ..< uris.count {
                
                newData.append( DeluxeData( type: .link, caption: uri_descriptions[link], value: uris[link] ) )
            }
            
            if !newData.isEmpty {
                
                deluxeData.append( newData )
            }
        }
        
        if 1 < self.covers.count {

            newData = [DeluxeData]()
            
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
        
        newData = [DeluxeData]()
        
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

extension OLEditionDetail {
    
    /// A struct to represent a parsed edition
    class ParsedFromJSON: OpenLibraryObject {
        
        // MARK: Properties.
        let key: String
        let created: NSDate?
        let last_modified: NSDate?
        let revision: Int64
        let latest_revision: Int64
        let type: String
        
        let title: String                        // of type /type/string
        let title_prefix: String                 // of type /type/string
        let subtitle: String                     // of type /type/string
        let other_titles: [String]               // of type /type/string
        let authors: [String]                    // of type /type/author
        let by_statement: String                 // of type /type/string
        let publish_date: String                 // of type /type/string
        let copyright_date: String               // of type /type/string
        let edition_name: String                 // of type /type/string
        let languages: [String]                  // of type /type/language
        let edition_description: String          // of type /type/text
        let notes: String                        // of type /type/text
        let genres: [String]                     // of type /type/string
        let table_of_contents: [[String: AnyObject]] // of type /type/toc_item
        let work_titles: [String]                // of type /type/string
        let series: [String]                     // of type /type/string
        let physical_dimensions: String          // of type /type/string
        let physical_format: String              // of type /type/string
        let number_of_pages: Int64               // of type /type/int
        let subjects: [String]                   // of type /type/string
        let pagination: String                   // of type /type/string
        let lccn: [String]                       // of type /type/string
        let ocaid: String                        // of type /type/string
        let oclc_numbers: [String]               // of type /type/string
        let isbn_10: [String]                    // of type /type/string
        let isbn_13: [String]                    // of type /type/string
        let dewey_decimal_class: [String]        // of type /type/string
        let lc_classifications: [String]         // of type /type/string
        let contributions: [String]              // of type /type/string
        let publish_places: [String]             // of type /type/string
        let publish_country: String              // of type /type/string
        let publishers: [String]                 // of type /type/string
        let distributors: [String]               // of type /type/string
        let first_sentence: String               // of type /type/text
        let weight: String                       // of type /type/string
        let location: [String]                   // of type /type/string
        let scan_on_demand: Bool                 // of type /type/boolean
        let collections: [String]                // of type /type/collection
        let uris: [String]                       // of type /type/string
        let uri_descriptions: [String]           // of type /type/string
        let translation_of: String               // of type /type/string
        let works: [String]                      // of type /type/work
        let source_records: [String]             // of type /type/string
        let translated_from: [String]           // of type /type/language
        //    let scan_records[]: [String]      // of type /type/scan_record
        //    let volumes[]: [String]           // of type /type/volume
        let accompanying_material: String       // of type /type/string
        let covers: [Int]
        
        // MARK: Initialization
        
        class func fromJSON( json: [String: AnyObject] ) -> ParsedFromJSON? {
            
            guard let revision = json["revision"] as? Int else { return nil }
            
            guard let latest_revision = json["latest_revision"] as? Int else { return nil }
            
            let created = OpenLibraryObject.OLTimeStamp( json["created"] )
            
            let last_modified = OpenLibraryObject.OLTimeStamp( json["last_modified"] )
            
            let type = OpenLibraryObject.OLKeyedValue( json["type"], key: "key" )
            
            guard let key = json["key"] as? String where !key.isEmpty else { return nil }
            
            guard let title = json["title"] as? String where !title.isEmpty else { return nil }
            
            let title_prefix = OpenLibraryObject.OLString( json["title_prefix"] )
            
            let subtitle = OpenLibraryObject.OLString( json["subtitle"] )
            
            let other_titles = OpenLibraryObject.OLStringArray( json["other_titles"] )
            
            // authors
            let authors = OpenLibraryObject.OLKeyedValueArray( json["authors"], key: "key" )
            
            let by_statement = OpenLibraryObject.OLString( json["by_statement"] )
            
            let publish_date = OpenLibraryObject.OLString( json["publish_date"] )
            
            let copyright_date = OpenLibraryObject.OLString( json["copyright_date"] )
            
            let edition_name = OpenLibraryObject.OLString( json["edition_name"] )
            
            let languages = OpenLibraryObject.OLKeyedValueArray( json["languages"], key: "key" )
            
            let edition_description = OpenLibraryObject.OLText( json["description"] )
            
            let notes = OpenLibraryObject.OLText( json["notes"] )
            
            let genres = OpenLibraryObject.OLStringArray( json["genres"] )
            
            let table_of_contents = OpenLibraryObject.OLTableOfContents( json["table_of_contents"] )
            
            let work_titles = OpenLibraryObject.OLStringArray( json["work_titles"] )
            
            let series = OpenLibraryObject.OLStringArray( json["series"] )
            
            let physical_dimensions = OpenLibraryObject.OLString( json["physical_dimensions"] )
            
            let physical_format = OpenLibraryObject.OLString( json["physical_format"] )
            
            let number_of_pages = OpenLibraryObject.OLInt( json["number_of_pages"] )
            
            let subjects = OpenLibraryObject.OLStringArray( json["subjects"] )
            
            let pagination = OpenLibraryObject.OLString( json["pagination"] )
            
            let lccn = OpenLibraryObject.OLStringArray( json["lccn"] )
            
            let ocaid = OpenLibraryObject.OLString( json["ocaid"] )
            
            let oclc_numbers = OpenLibraryObject.OLStringArray( json["oclc_numbers"] )
            
            let isbn_10 = OpenLibraryObject.OLStringArray( json["isbn_10"] )
            
            let isbn_13 = OpenLibraryObject.OLStringArray( json["isbn_13"] )
            
            let dewey_decimal_class = OpenLibraryObject.OLStringArray( json["dewey_decimal_class"] )
            
            let lc_classifications = OpenLibraryObject.OLStringArray( json["lc_classifications"] )
            
            let contributions = OpenLibraryObject.OLStringArray( json["contributions"] )
            
            let publish_places = OpenLibraryObject.OLStringArray( json["publish_places"] )
            
            let publish_country = OpenLibraryObject.OLString( json["publish_country"] )
            
            let publishers = OpenLibraryObject.OLStringArray( json["publishers"] )
            
            let distributors = OpenLibraryObject.OLStringArray( json["distributors"] )
            
            let first_sentence = OpenLibraryObject.OLText( json["first_sentence"] )
            
            let weight = OpenLibraryObject.OLString( json["weight"] )
            
            let location = OpenLibraryObject.OLStringArray( json["location"] )
            
            let scan_on_demand = OpenLibraryObject.OLBool( json["scan_on_demand"] )
            
            let collections = OpenLibraryObject.OLKeyedValueArray( json["collections"], key: "name" )
            
            let uris = OpenLibraryObject.OLStringArray( json["uris"] )
            
            let uri_descriptions = OpenLibraryObject.OLStringArray( json["uri_descriptions"] )
            
            let translation_of = OpenLibraryObject.OLString( json["translation_of"] )
            
            let works = OpenLibraryObject.OLKeyedValueArray( json["works"], key: "key" )
            
            let source_records = OpenLibraryObject.OLStringArray( json["source_records"] )
            
            let translated_from = OpenLibraryObject.OLKeyedValueArray( json["translated_from"], key: "key" )
            //    let scan_records[]: AnyObject,
            //    let volumes[]: AnyObject,
            let accompanying_material = OpenLibraryObject.OLString( json["accompanying_material"] )
            
            let covers = OpenLibraryObject.OLIntArray( json["covers"] )
            
            return ParsedFromJSON(
                key: key,
                created: created,
                last_modified: last_modified,
                revision: Int64( revision ),
                latest_revision: Int64( latest_revision ),
                type: type,
                
                title: title,
                title_prefix: title_prefix,
                subtitle: subtitle,
                other_titles: other_titles,
                authors: authors,
                by_statement: by_statement,
                publish_date: publish_date,
                copyright_date: copyright_date,
                edition_name: edition_name,
                languages: languages,
                edition_description: edition_description,
                notes: notes,
                genres: genres,
                table_of_contents: table_of_contents,
                work_titles: work_titles,
                series: series,
                physical_dimensions: physical_dimensions,
                physical_format: physical_format,
                number_of_pages: Int64( number_of_pages ),
                subjects: subjects,
                pagination: pagination,
                lccn: lccn,
                ocaid: ocaid,
                oclc_numbers: oclc_numbers,
                isbn_10: isbn_10,
                isbn_13: isbn_13,
                dewey_decimal_class: dewey_decimal_class,
                lc_classifications: lc_classifications,
                contributions: contributions,
                publish_places: publish_places,
                publish_country: publish_country,
                publishers: publishers,
                distributors: distributors,
                first_sentence: first_sentence,
                weight: weight,
                location: location,
                scan_on_demand: scan_on_demand,
                collections: collections,
                uris: uris,
                uri_descriptions: uri_descriptions,
                translation_of: translation_of,
                works: works,
                source_records: source_records,
                translated_from: translated_from,
                //    scan_records[]: AnyObject,
                //    volumes[]: AnyObject,
                accompanying_material: accompanying_material,
                covers: covers
            )
        }
        
        init(
            key: String,
            created: NSDate?,
            last_modified: NSDate?,
            revision: Int64,
            latest_revision: Int64,
            type: String,
            
            title: String,
            title_prefix: String,
            subtitle: String,
            other_titles: [String],
            authors: [String],
            by_statement: String,
            publish_date: String,
            copyright_date: String,
            edition_name: String,
            languages: [String],
            edition_description: String,
            notes: String,
            genres: [String],
            table_of_contents: [[String: AnyObject]],
            work_titles: [String],
            series: [String],
            physical_dimensions: String,
            physical_format: String,
            number_of_pages: Int64,
            subjects: [String],
            pagination: String,
            lccn: [String],
            ocaid: String,
            oclc_numbers: [String],
            isbn_10: [String],
            isbn_13: [String],
            dewey_decimal_class: [String],
            lc_classifications: [String],
            contributions: [String],
            publish_places: [String],
            publish_country: String,
            publishers: [String],
            distributors: [String],
            first_sentence: String,
            weight: String,
            location: [String],
            scan_on_demand: Bool,
            collections: [String],
            uris: [String],
            uri_descriptions: [String],
            translation_of: String,
            works: [String],
            source_records: [String],
            translated_from: [String],
            //    scan_records[]: [String],
            //    volumes[]: [String],
            accompanying_material: String,
            covers: [Int]
            ) {
            
            self.key = key
            self.created = created
            self.last_modified = last_modified
            self.revision = revision
            self.latest_revision = latest_revision
            self.type = type
            
            self.title = title
            self.title_prefix = title_prefix
            self.subtitle = subtitle
            self.other_titles = other_titles
            self.authors = authors
            self.by_statement = by_statement
            self.publish_date = publish_date
            self.copyright_date = copyright_date
            self.edition_name = edition_name
            self.languages = languages
            self.edition_description = edition_description
            self.notes = notes
            self.genres = genres
            self.table_of_contents = table_of_contents
            self.work_titles = work_titles
            self.series = series
            self.physical_dimensions = physical_dimensions
            self.physical_format = physical_format
            self.number_of_pages = number_of_pages
            self.subjects = subjects
            self.pagination = pagination
            self.lccn = lccn
            self.ocaid = ocaid
            self.oclc_numbers = oclc_numbers
            self.isbn_10 = isbn_10
            self.isbn_13 = isbn_13
            self.dewey_decimal_class = dewey_decimal_class
            self.lc_classifications = lc_classifications
            self.contributions = contributions
            self.publish_places = publish_places
            self.publish_country = publish_country
            self.publishers = publishers
            self.distributors = distributors
            self.first_sentence = first_sentence
            self.weight = weight
            self.location = location
            self.scan_on_demand = scan_on_demand
            self.collections = collections
            self.uris = uris
            self.uri_descriptions = uri_descriptions
            self.translation_of = translation_of
            self.works = works
            self.source_records = source_records
            self.translated_from = translated_from
            //    self.scan_records[] = AnyObject
            //    self.volumes[] = AnyObject
            self.accompanying_material = accompanying_material
            self.covers = covers
        }
    }
}
