//  WorkEditionsParseOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation
import CoreData

import BNRCoreDataStack

/// A struct to represent a parsed work
private class ParsedSearchResult: OpenLibraryObject {
    
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
    let table_of_contents: [[String: String]] // of type /type/toc_item
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
    
    class func fromJSON( match: [String: AnyObject] ) -> ParsedSearchResult? {
        
        guard let revision = match["revision"] as? Int else { return nil }
        
        guard let latest_revision = match["latest_revision"] as? Int else { return nil }
        
        let created = OpenLibraryObject.OLTimeStamp( match["created"] )
        
        let last_modified = OpenLibraryObject.OLTimeStamp( match["last_modified"] )
        
        let type = OpenLibraryObject.OLKeyedValue( match["type"], key: "key" )
        
        guard let key = match["key"] as? String where !key.isEmpty else { return nil }
        
        guard let title = match["title"] as? String where !title.isEmpty else { return nil }

        let title_prefix = OpenLibraryObject.OLString( match["title_prefix"] )
        
        let subtitle = OpenLibraryObject.OLString( match["subtitle"] )
        
        let other_titles = OpenLibraryObject.OLStringArray( match["other_titles"] )
        
        // authors
        let authors = OpenLibraryObject.OLKeyedValueArray( match["authors"], key: "key" )
        
        let by_statement = OpenLibraryObject.OLString( match["by_statement"] )
        
        let publish_date = OpenLibraryObject.OLString( match["publish_date"] )
        
        let copyright_date = OpenLibraryObject.OLString( match["copyright_date"] )
        
        let edition_name = OpenLibraryObject.OLString( match["edition_name"] )
        
        let languages = OpenLibraryObject.OLKeyedValueArray( match["languages"], key: "key" )
        
        let edition_description = OpenLibraryObject.OLText( match["description"] )
        
        let notes = OpenLibraryObject.OLText( match["notes"] )
        
        let genres = OpenLibraryObject.OLStringArray( match["genres"] )
        
        let table_of_contents = OpenLibraryObject.OLStringStringDictionaryArray( match["table_of_contents"] )
        
        let work_titles = OpenLibraryObject.OLStringArray( match["work_titles"] )
        
        let series = OpenLibraryObject.OLStringArray( match["series"] )
        
        let physical_dimensions = OpenLibraryObject.OLString( match["physical_dimensions"] )
        
        let physical_format = OpenLibraryObject.OLString( match["physical_format"] )
        
        let number_of_pages = OpenLibraryObject.OLInt( match["number_of_pages"] )
        
        let subjects = OpenLibraryObject.OLStringArray( match["subjects"] )
        
        let pagination = OpenLibraryObject.OLString( match["pagination"] )
        
        let lccn = OpenLibraryObject.OLStringArray( match["lccn"] )
        
        let ocaid = OpenLibraryObject.OLString( match["ocaid"] )
        
        let oclc_numbers = OpenLibraryObject.OLStringArray( match["oclc_numbers"] )
        
        let isbn_10 = OpenLibraryObject.OLStringArray( match["isbn_10"] )
        
        let isbn_13 = OpenLibraryObject.OLStringArray( match["isbn_13"] )
        
        let dewey_decimal_class = OpenLibraryObject.OLStringArray( match["dewey_decimal_class"] )
        
        let lc_classifications = OpenLibraryObject.OLStringArray( match["lc_classifications"] )
        
        let contributions = OpenLibraryObject.OLStringArray( match["contributions"] )
        
        let publish_places = OpenLibraryObject.OLStringArray( match["publish_places"] )
        
        let publish_country = OpenLibraryObject.OLString( match["publish_country"] )
        
        let publishers = OpenLibraryObject.OLStringArray( match["publishers"] )
        
        let distributors = OpenLibraryObject.OLStringArray( match["distributors"] )
        
        let first_sentence = OpenLibraryObject.OLText( match["first_sentence"] )
        
        let weight = OpenLibraryObject.OLString( match["weight"] )
        
        let location = OpenLibraryObject.OLStringArray( match["location"] )
        
        let scan_on_demand = OpenLibraryObject.OLBool( match["scan_on_demand"] )
        
        let collections = OpenLibraryObject.OLKeyedValueArray( match["collections"], key: "name" )
        
        let uris = OpenLibraryObject.OLStringArray( match["uris"] )
        
        let uri_descriptions = OpenLibraryObject.OLStringArray( match["uri_descriptions"] )
        
        let translation_of = OpenLibraryObject.OLString( match["translation_of"] )
        
        let works = OpenLibraryObject.OLKeyedValueArray( match["works"], key: "key" )
        
        let source_records = OpenLibraryObject.OLStringArray( match["source_records"] )
        
        let translated_from = OpenLibraryObject.OLKeyedValueArray( match["translated_from"], key: "key" )
        //    let scan_records[]: AnyObject,
        //    let volumes[]: AnyObject,
        let accompanying_material = OpenLibraryObject.OLString( match["accompanying_material"] )
        
        let covers = OpenLibraryObject.OLIntArray( match["covers"] )
        
        return ParsedSearchResult(
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
        table_of_contents: [[String: String]],
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

/// An `Operation` to parse Editions out of a query from OpenLibrary.
class WorkEditionsParseOperation: Operation {
    
    let parentKey: String
    let offset: Int
    let limit: Int
    let withCoversOnly: Bool
    let cacheFile: NSURL
    let context: NSManagedObjectContext
    let updateResults: SearchResultsUpdater
    
    var searchResults = SearchResults()
    
    /**
        - parameter cacheFile: The file `NSURL` from which to load author query data.
        - parameter context: The `NSManagedObjectContext` that will be used as the
                             basis for importing data. The operation will internally
                             construct a new `NSManagedObjectContext` that points
                             to the same `NSPersistentStoreCoordinator` as the
                             passed-in context.
    */
    init( parentKey: String, offset: Int, limit: Int, withCoversOnly: Bool, cacheFile: NSURL, coreDataStack: CoreDataStack, updateResults: SearchResultsUpdater ) {
        
        /*
            Use the overwrite merge policy, because we want any updated objects
            to replace the ones in the store.
        */
        
        self.cacheFile = cacheFile
        self.context = coreDataStack.newBackgroundWorkerMOC()
        self.context.mergePolicy = NSOverwriteMergePolicy
        self.updateResults = updateResults
        self.withCoversOnly = withCoversOnly
        self.limit = limit
        self.offset = offset
        self.parentKey = parentKey
        
        super.init()

        name = "Parse Work Editions"
    }
    
    override func execute() {
        guard let stream = NSInputStream(URL: cacheFile) else {
            finish()
            return
        }
        
        stream.open()
        
        defer {
            stream.close()
        }
        
        do {
            if let json = try NSJSONSerialization.JSONObjectWithStream(stream, options: []) as? [String: AnyObject] {
            
                parse( json )
            }
            else {
                finish()
            }
        }
        catch let jsonError as NSError {
            finishWithError(jsonError)
        }
    }
    
    private func parse( resultSet: [String: AnyObject] ) {

        guard var numFound = resultSet["size"] as? Int else {
            
            updateResults( SearchResults( start: offset, numFound: offset, pageSize: 0 ) )
            finishWithError( nil )
            return
        }
        
        guard let entries = resultSet["entries"] as? [[String: AnyObject]] else {
            
            updateResults( SearchResults( start: offset, numFound: offset, pageSize: 0 ) )
            finishWithError( nil )
            return
        }
        
        if 0 == numFound {
            
            numFound = offset + entries.count
        }
        
        if 0 == numFound {
            
            updateResults( SearchResults( start: offset, numFound: offset, pageSize: 0 ) )
            finishWithError( nil )
            return
        }
        
        if entries.count < limit {
            numFound = min( numFound, offset + entries.count )
        }
        
        context.performBlock {
            
            var index = self.offset
            for entry in entries {
                
                if let newEntry = ParsedSearchResult.fromJSON( entry ) {
                    
                    self.insert( self.parentKey, index: index, parsed: newEntry )
                
                    index += 1
 
                    print( "\(self.parentKey) \(newEntry.key) \(newEntry.title)" )
                }
            }

            let error = self.saveContext()

            if nil == error {
                self.updateResults( SearchResults( start: self.offset, numFound: numFound, pageSize: resultSet.count ) )
            } else {
                
                print( "\(error?.localizedDescription)" )
            }
        
            self.finishWithError( error )
        }
    }
    
    private func insert( workKey: String, index: Int, parsed: ParsedSearchResult ) {

        let result = NSEntityDescription.insertNewObjectForEntityForName( OLEditionDetail.entityName, inManagedObjectContext: context) as! OLEditionDetail

        result.work_key = workKey
        result.author_key = parsed.authors.isEmpty ? "" : parsed.authors[0]
        result.index = Int64( index )
        
        result.key = parsed.key
        result.created = parsed.created
        result.last_modified = parsed.last_modified
        result.revision = parsed.revision
        result.latest_revision = parsed.latest_revision
        result.type = parsed.type
        
        result.accompanying_material = parsed.accompanying_material
        result.authors = parsed.authors
        result.by_statement = parsed.by_statement
        result.collections = parsed.collections
        result.contributions = parsed.contributions
        result.copyright_date = parsed.copyright_date
        result.covers = parsed.covers
        result.coversFound = parsed.covers.count > 0
        result.dewey_decimal_class = parsed.dewey_decimal_class
        result.distributors = parsed.distributors
        result.edition_description = parsed.edition_description
        result.edition_name = parsed.edition_name
        result.first_sentence = parsed.first_sentence
        result.genres = parsed.genres
        result.isbn_10 = parsed.isbn_10
        result.isbn_13 = parsed.isbn_13
        result.languages = parsed.languages
        result.lc_classifications = parsed.lc_classifications
        result.lccn = parsed.lccn
        result.location = parsed.location
        result.notes = parsed.notes
        result.number_of_pages = parsed.number_of_pages
        result.ocaid = parsed.ocaid
        result.oclc_numbers = parsed.oclc_numbers
        result.other_titles = parsed.other_titles
        result.pagination = parsed.pagination
        result.physical_dimensions = parsed.physical_dimensions
        result.physical_format = parsed.physical_format
        result.publish_country = parsed.publish_country
        result.publish_date = parsed.publish_date
        result.publish_places = parsed.publish_places
        result.publishers = parsed.publishers
        result.scan_on_demand = parsed.scan_on_demand
        result.series = parsed.series
        result.source_records = parsed.source_records
        result.subjects = parsed.subjects
        result.subtitle = parsed.subtitle
        result.table_of_contents = parsed.table_of_contents
        result.title = parsed.title
        result.title_prefix = parsed.title_prefix
        result.translated_from = parsed.translated_from
        result.translation_of = parsed.translation_of
        result.uri_descriptions = parsed.uri_descriptions
        result.uris = parsed.uris
        result.weight = parsed.weight
        result.work_titles = parsed.work_titles
        result.works = parsed.works    }
        //    result.scan_records[] = parsed.AnyObject
        //    result.volumes[] = parsed.AnyObject
    
    /**
        Save the context, if there are any changes.
    
        - returns: An `NSError` if there was an problem saving the `NSManagedObjectContext`,
            otherwise `nil`.
    
        - note: This method returns an `NSError?` because it will be immediately
            passed to the `finishWithError()` method, which accepts an `NSError?`.
    */
    private func saveContext() -> NSError? {
        var error: NSError?

        do {
            try context.saveContextAndWait()
        }
        catch let saveError as NSError {
            error = saveError
        }

        return error
    }
    
    func Update( searchResults: SearchResults ) {
        
        self.searchResults = searchResults
    }
}
