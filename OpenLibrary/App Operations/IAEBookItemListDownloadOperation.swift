//  IAEBookItemListDownloadOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation

class IAEBookItemListDownloadOperation: GroupOperation {
    // MARK: Properties

    let cacheFile: NSURL
    
    // MARK: Initialization
    
    /// - parameter cacheFile: The file `NSURL` to which the list of author Editions will be downloaded.
    
    init( editionKeys: [String], cacheFile: NSURL ) {
        
        self.cacheFile = cacheFile
        super.init( operations: [] )
        name = "Download IAEBookItems for list of edition OLIDs"
        let urlString = "https://openlibrary.org/api/volumes/brief/json/"
        
        var olidString = ""
        
        for key in editionKeys {
            
            let parts = key.componentsSeparatedByString( "/" )
            let goodParts = parts.filter { (x) -> Bool in !x.isEmpty }
            let olid = goodParts.last!
            
            olidString += "OLID:" + olid + ";"
        }
            
        let url = NSURL( string: urlString + olidString )!
        let task = NSURLSession.sharedSession().downloadTaskWithURL( url ) {
            
            url, response, error in
            
            self.downloadFinished(url, response: response as? NSHTTPURLResponse, error: error)
        }
        
        let taskOperation = URLSessionTaskOperation(task: task)
        
        let reachabilityCondition = ReachabilityCondition(host: url)
        taskOperation.addCondition(reachabilityCondition)
        
        let networkObserver = NetworkObserver()
        taskOperation.addObserver(networkObserver)
        
        addOperation(taskOperation)
    }
    
    func downloadFinished(url: NSURL?, response: NSHTTPURLResponse?, error: NSError?) {
        if let localURL = url {
            do {
                /*
                    If we already have a file at this location, just delete it.
                    Also, swallow the error, because we don't really care about it.
                */
                try NSFileManager.defaultManager().removeItemAtURL(cacheFile)
            }
            catch { }
            
            do {
                try NSFileManager.defaultManager().moveItemAtURL(localURL, toURL: cacheFile)
            }
            catch let error as NSError {
                aggregateError(error)
            }
            
        }
        else if let error = error {
            aggregateError(error)
        }
        else {
            // Do nothing, and the operation will automatically finish.
        }
    }
}
