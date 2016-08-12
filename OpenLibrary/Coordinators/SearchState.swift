//
//  SearchState.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 8/9/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

private let kSearchFields = "SearchFields"
private let kSortFields = "SortFields"
private let kSearchResults = "SearchResults"
private let kSearchSequence = "SearchSequence"

class SortField: NSObject {
    
    static private let fields: [( name: String, label: String )] = [
        ( name: "sort_author_name", label: "Author" ),
        ( name: "title", label: "Title" ),
        ( name: "edition_count", label: "Edition Count" ),
        ( name: "ebook_count_i", label: "Electronic Editions" ),
        ( name: "first_publish_year", label: "Year First Published" )
    ]
    
    class func decode( coder aDecoder: NSCoder ) -> [SortField] {
    
        var sortFields: [SortField] = []
        for field in SortField.fields {
        
            let rawSort = aDecoder.decodeIntForKey( field.name ) ?? 0
            sortFields.append(
                SortField(
                        name: field.name,
                        label: field.label,
                        sort: SortOptions( rawValue: Int( rawSort ) ) ?? .sortNone
                    )
                )
        }
        
        return sortFields
    }
    
    class func encode( aCoder: NSCoder, sortFields: [SortField] ) {
        
        for field in sortFields {
            
            field.encodeWithCoder( aCoder )
        }
    }
    
    let name: String
    let label: String
    var sort: SortOptions
    
    init( name: String, label: String, sort: SortOptions ) {
        
        self.name = name
        self.label = label
        self.sort = sort
    }
    
    func encodeWithCoder( aCoder: NSCoder ) {
        
        aCoder.encodeInt( Int32( sort.rawValue ), forKey: name )
    }
    
    func image() -> UIImage {
        
        return UIImage( named: sort.imageName )!
    }
}

enum SortOptions: Int {
    
    case sortNone = 0, sortUp = 1, sortDown = 2, sortMax  = 3
    
    var imageName: String {
        
        switch self {
        case sortNone: return "rsw-notsorted-28x26"
        case sortUp:   return "763-arrow-up"
        case sortDown: return "764-arrow-down"
        case sortMax:
            assert( self != sortMax )
            return ""
        }
    }
    
    func nextSort() -> SortOptions {
        
        let rawNext = self.rawValue + 1
        let rawMax  = sortMax.rawValue
        
        let rawNew = rawNext % rawMax
        
        return SortOptions( rawValue: rawNew )!
    }
    
    var ascending: Bool {
        
        return self == .sortUp
    }
}

class SearchState: NSObject, NSCoding {
    
    static let DocumentsDirectory = NSFileManager().URLsForDirectory( .DocumentDirectory, inDomains: .UserDomainMask ).first!
    static let ArchiveURL = DocumentsDirectory.URLByAppendingPathComponent( "SearchState" )
    
    class func loadState() -> SearchState? {
        
        return NSKeyedUnarchiver.unarchiveObjectWithFile( SearchState.ArchiveURL.path! ) as? SearchState
    }
    
    var searchFields: [String: String] = [:]
    var sortFields: [SortField] = []
    var searchResults = SearchResults()
    var sequence: Int
    
    init( searchFields: [String: String], sortFields: [SortField], searchResults: SearchResults, sequence: Int ) {
        
        self.searchFields = searchFields
        self.sortFields = sortFields
        self.searchResults = searchResults
        self.sequence = sequence
    }
    
    required init( coder aDecoder: NSCoder ) {
        
        searchFields = aDecoder.decodeObjectForKey( kSearchFields ) as? [String: String] ?? [:]
        sortFields = SortField.decode( coder: aDecoder )
        searchResults = aDecoder.decodeObjectForKey( kSearchResults ) as? SearchResults ?? SearchResults()
        sequence = Int( aDecoder.decodeInt64ForKey( kSearchSequence ) ?? 1 )
    }

    func encodeWithCoder( aCoder: NSCoder ) {
        
        aCoder.encodeObject( searchFields, forKey: kSearchFields )
        SortField.encode( aCoder, sortFields: sortFields )
        aCoder.encodeObject( searchResults, forKey: kSearchResults )
        aCoder.encodeInt64( Int64( sequence ), forKey: kSearchSequence )
    }
    
    func saveState() {
        
        let saveSuccess = NSKeyedArchiver.archiveRootObject( self, toFile: SearchState.ArchiveURL.path! )
        if !saveSuccess {
            
            print( "SearchState.saveState failed" )
        }
    }
    
}
