//  IAEBookItemListGetOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

//  https://openlibrary.org/works/OL262759W/editions.json?*=

import CoreData

import BNRCoreDataStack
import PSOperations

/// A composite `Operation` to both download and parse eBook item information in groups of 256.
class IAEBookItemListGetOperation: GroupOperation {

    // MARK: Properties
    private var operations: [NSOperation] = []
    private let finishOperation: NSBlockOperation
    
    /**
     
        - parameter editionKeys: The array of edition keys for which eBook item 
                                 information will be retrieved
     
        - parameter context: The `NSManagedObjectContext` into which the parsed
                             eBook items will be imported.

        - parameter completionHandler: The handler to call after downloading and
                                       parsing are complete. This handler will be
                                       invoked on an arbitrary queue.
    */
    init( editionKeys: [String], coreDataStack: CoreDataStack, completionHandler: Void -> Void ) {
        
        let cachesFolder = try! NSFileManager.defaultManager().URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        
        /*
         This operation is made of these child operations:
         
         1. The operation to download the JSON feed
         2. The operation to parse the JSON feed and insert the elements into the Core Data store
         
         repeated as necessary to download eBook item information in chunks of 256
         
         3. The operation to invoke the completion handler
         */
        var index = 0
        let subsetSize = 256
        while index < editionKeys.count {
            
            let subset = Array( editionKeys[index ..< min( editionKeys.count, index + subsetSize )] )
            
            var olid = ""
            if let editionKey = subset.first {
                
                let parts = editionKey.componentsSeparatedByString( "/" )
                let goodParts = parts.filter { (x) -> Bool in !x.isEmpty }
                olid = goodParts.last!
            }
            let cacheFile =
                cachesFolder.URLByAppendingPathComponent( "\(olid)InternetArchiveEBookItems.json")
            //       print( "cache: \(cacheFile.absoluteString)" )
            
            let urlString = IAEBookItemListDownloadOperation.urlString( subset )
            
            let downloadOperation = IAEBookItemListDownloadOperation( editionKeys: subset, cacheFile: cacheFile )
            if let previousOperation = operations.last {
                
                downloadOperation.addDependency( previousOperation )
            }
            operations.append( downloadOperation )

            let parseOperation = IAEBookItemListParseOperation( urlString: urlString, cacheFile: cacheFile, coreDataStack: coreDataStack )
            
            parseOperation.addDependency( operations.last! )
            
            operations.append( parseOperation )

            index += subsetSize
        }

        finishOperation = NSBlockOperation( block: completionHandler )

        if let previousOperation = operations.last {
            finishOperation.addDependency( previousOperation )
        }
        
        super.init( operations: operations )
        
        addOperation( finishOperation )
        
        addCondition( MutuallyExclusive<IAEBookItemListGetOperation>() )
        
        name = "Get IAEBookItems"
    }
    
    override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {

        if let firstError = errors.first where operations.contains( operation ) {

            produceAlert( firstError )
        }
    }
    
}

