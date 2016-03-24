//
//  SearchResults.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/26/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

struct SearchResults {
    
    let start:    Int
    let numFound: Int
    let pageSize: Int

    init() {
        
        start    = 0
        numFound = 0
        pageSize = 0
    }
    
    init( start: Int, numFound: Int, pageSize: Int ) {
        
        self.start    = start
        self.numFound = numFound
        self.pageSize = pageSize
    }
}

typealias SearchResultsUpdater = SearchResults -> Void


