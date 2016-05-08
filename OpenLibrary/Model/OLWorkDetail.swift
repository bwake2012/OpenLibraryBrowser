//
//  OLWorkDetail.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/14/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

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
    
    class func fromJSON( match: [String: AnyObject] ) -> ParsedSearchResult? {
        
        guard let key = match["key"] as? String where !key.isEmpty else { return nil }
        
        guard let title = match["title"] as? String where !title.isEmpty else { return nil }
        
        let subtitle = OpenLibraryObject.OLString( match["subtitle"] )
        
        // authors
        let authors = OpenLibraryObject.OLAuthorRole( match["authors"] )
        
        let translated_titles = OpenLibraryObject.OLStringArray( match["translated_titles"] )
        
        let subjects = OpenLibraryObject.OLStringArray( match["subjects"] )
        
        let subject_places = OpenLibraryObject.OLStringArray( match["subject_places"] )
        
        let subject_times = OpenLibraryObject.OLStringArray( match["subject_times"] )
        
        let subject_people = OpenLibraryObject.OLStringArray( match["subject_people"] )
        
        let work_description = OpenLibraryObject.OLText( match["description"] )
        
        let dewey_number = OpenLibraryObject.OLStringArray( match["dewey_number"] )
        
        let lc_classifications = OpenLibraryObject.OLStringArray( match["lc_classifications"] )
        
        let first_sentence = OpenLibraryObject.OLText( match["first_sentence"] )
        
        let original_languages = OpenLibraryObject.OLStringArray( match["original_languages"] )
        
        let other_titles = OpenLibraryObject.OLStringArray( match["other_titles"] )
        
        let first_publish_date = OpenLibraryObject.OLDateStamp( "first_publish_date" )
        
        let links = OpenLibraryObject.OLLinks( match )
        
        let notes = OpenLibraryObject.OLText( match["notes"] )
        
        let covers = OpenLibraryObject.OLIntArray( match["covers"] )
        
        var revision = Int64( 0 )
        if let r = match["revision"] as? Int64 {
            
            revision = r
        }
        
        var latest_revision = Int64( 0 )
        if let lr = match["latest_revision"] as? Int64 {
            
            latest_revision = lr
        }
        
        let created = OpenLibraryObject.OLTimeStamp( match["created"] )
        
        let last_modified = OpenLibraryObject.OLTimeStamp( match["last_modified"] )
        
        let type = match["type"] as? String ?? ""
        
        return ParsedSearchResult( key: key, created: created, last_modified: last_modified, revision: revision, latest_revision: latest_revision, type: type, title: title, subtitle: subtitle, authors: authors, translated_titles: translated_titles, subjects: subjects, subject_places: subject_places, subject_times: subject_times, subject_people: subject_people, work_description: work_description, dewey_number: dewey_number, lc_classifications: lc_classifications, first_sentence: first_sentence, original_languages: original_languages, other_titles: other_titles, first_publish_date: first_publish_date, links: links, notes: notes, covers: covers )
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

class OLWorkDetail: OLManagedObject, CoreDataModelable {

    // MARK: Search Info
    struct SearchInfo {
        
        let objectID: NSManagedObjectID
        let key: String
    }
    
    static let entityName = "WorkDetail"
    
    class func parseJSON( parentKey: String, index: Int, json: [String: AnyObject], moc: NSManagedObjectContext ) -> OLWorkDetail? {
        
        guard let parsed = ParsedSearchResult.fromJSON( json ) else { return nil }
            
        guard let newObject =
            NSEntityDescription.insertNewObjectForEntityForName(
                    OLWorkDetail.entityName, inManagedObjectContext: moc
                ) as? OLWorkDetail else { return nil }
            
        if parentKey.hasPrefix( "/authors/" ) {
            newObject.author_key = parentKey
        } else if parentKey.hasPrefix( "/works/" ) {
            newObject.work_key = parentKey
        }
        if newObject.author_key.isEmpty && !parsed.authors.isEmpty {
            newObject.author_key = parsed.authors[0]
        }
        
        newObject.index = Int64( index )
        
        newObject.key = parsed.key
        newObject.created = parsed.created
        newObject.last_modified = parsed.last_modified
        newObject.revision = parsed.revision
        newObject.latest_revision = parsed.latest_revision
        newObject.type = parsed.type
        
        newObject.title = parsed.title
        newObject.subtitle = parsed.subtitle
        newObject.authors = parsed.authors
        newObject.translated_titles = parsed.translated_titles
        newObject.subjects = parsed.subjects
        newObject.subject_places = parsed.subject_places
        newObject.subject_times = parsed.subject_times
        newObject.subject_people = parsed.subject_people
        newObject.work_description = parsed.work_description
        newObject.dewey_number = parsed.dewey_number
        newObject.lc_classifications = parsed.lc_classifications
        newObject.first_sentence = parsed.first_sentence
        newObject.original_languages = parsed.original_languages
        newObject.other_titles = parsed.other_titles
        newObject.first_publish_date = parsed.first_publish_date
        newObject.links = parsed.links
        newObject.notes = parsed.notes
        // cover_edition of type /type/edition
        newObject.covers = parsed.covers
        newObject.coversFound = parsed.covers.count > 0 && -1 != parsed.covers[0]
        
        return newObject
    }
    
    override var heading: String {
        
        return self.title
    }
    
    override var hasImage: Bool {
        
        return self.coversFound
    }
    
    override var firstImageID: Int {
        
        return 0 >= self.covers.count ? 0 : self.covers[0]
    }
    
    override func imageID( index: Int ) -> Int {
        
        return index >= self.covers.count ? 0 : self.covers[index]
    }
    
    override func localURL( size: String, index: Int = 0 ) -> NSURL {
        
        return super.localURL( self.key, size: size, index: index )
    }
    
    override func buildDeluxeData() -> [[DeluxeData]] {
        
        var deluxeData = [[DeluxeData]]()
        
        deluxeData.append( [DeluxeData( type: .heading, caption: "Title", value: self.title )] )
        if !subtitle.isEmpty {
            deluxeData[0].append( DeluxeData( type: .subheading, caption: "Subtitle:", value: self.subtitle ) )
        }
        
        if hasImage {
            
            let value = localURL( "M" ).absoluteString
            deluxeData.append(
                [DeluxeData( type: .image, caption: String( firstImageID ), value: value )]
            )
            
        }
        
        if !self.work_description.isEmpty {
            
            deluxeData.append( [DeluxeData( type: .block, caption: "Description", value: self.work_description )] )
        }
        
        if !self.first_sentence.isEmpty {
            
            deluxeData.append( [DeluxeData( type: .block, caption: "First Sentence", value: self.first_sentence )] )
        }
        
        if !self.notes.isEmpty {
            
            deluxeData.append( [DeluxeData( type: .block, caption: "Notes", value: self.notes )] )
        }
        
        if !self.links.isEmpty {
            
            var newData = [DeluxeData]()
            
            for link in self.links {
                
                if let title = link["title"], url = link["url"] {
                    newData.append( DeluxeData( type: .link, caption: title, value: url ) )
                    print( "\(title) \(url)" )
                }
            }
            
            if 0 < newData.count {
                
                deluxeData.append( newData )
            }
        }
        
        if 1 < self.covers.count {
            
            var newData = [DeluxeData]()
            
            for index in 1..<self.covers.count {
                
                if -1 != covers[index] {
                    
                    let value = localURL( "M", index: index ).absoluteString
                    newData.append(
                        DeluxeData( type: .image, caption: String( covers[index] ), value: value )
                    )
                }
            }
            
            if !newData.isEmpty {
                
                deluxeData.append( newData )
            }
        }

        return deluxeData
    }
}
