//
//  SearchResults.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/26/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

private let kResultsStart = "SearchResultsStart"
private let kResultsNumFound = "SearchResultsNumFound"
private let kResultsPageSize = "SearchResultsPageSize"

class SearchResults: NSObject, NSCoding {
    
    let start:    Int
    let numFound: Int
    let pageSize: Int

    override init() {
        
        start    = 0
        numFound = 0
        pageSize = 0
        
        super.init()
    }
    
    init( start: Int, numFound: Int, pageSize: Int ) {
        
        self.start    = start
        self.numFound = numFound
        self.pageSize = pageSize
    }
    
    required init( coder aDecoder: NSCoder ) {
    
        start = Int( aDecoder.decodeIntForKey( kResultsStart ) ?? 0 )
        numFound = Int( aDecoder.decodeIntForKey( kResultsNumFound ) ?? 0 )
        pageSize = Int( aDecoder.decodeIntForKey( kResultsPageSize ) ?? 0 )
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
        aCoder.encodeInt( Int32( start ), forKey: kResultsStart )
        aCoder.encodeInt( Int32( numFound ), forKey: kResultsNumFound )
        aCoder.encodeInt( Int32( pageSize ), forKey: kResultsPageSize )
    }
}

typealias SearchResultsUpdater = SearchResults -> Void


