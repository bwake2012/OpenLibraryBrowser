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
    
        start = Int( aDecoder.decodeCInt( forKey: kResultsStart ) )
        numFound = Int( aDecoder.decodeCInt( forKey: kResultsNumFound ) )
        pageSize = Int( aDecoder.decodeCInt( forKey: kResultsPageSize ) )
    }
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encodeCInt( Int32( start ), forKey: kResultsStart )
        aCoder.encodeCInt( Int32( numFound ), forKey: kResultsNumFound )
        aCoder.encodeCInt( Int32( pageSize ), forKey: kResultsPageSize )
    }
}

typealias SearchResultsUpdater = (SearchResults) -> Void


