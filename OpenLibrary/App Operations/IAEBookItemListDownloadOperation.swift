//  IAEBookItemListDownloadOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation

import PSOperations

class IAEBookItemListDownloadOperation: GroupOperation {
    // MARK: Properties

    let cacheFile: URL
    
    // MARK: class funcs
    class func urlString( _ editionKeys: [String] ) -> String {
        
        let urlString = "https://openlibrary.org/api/volumes/brief/json/"
        
        var olidString = ""
        
        for key in editionKeys {
            
            let parts = key.components( separatedBy: "/" )
            let goodParts = parts.filter { (x) -> Bool in !x.isEmpty }
            let olid = goodParts.last!
            
            olidString += "OLID:" + olid + ";"
        }
        
        return urlString + olidString

    }
    
    // MARK: Initialization
    
    /// - parameter cacheFile: The file `NSURL` to which the list of author Editions will be downloaded.
    
    init( editionKeys: [String], cacheFile: URL ) {
        
        self.cacheFile = cacheFile
        super.init( operations: [] )
        name = "Download IAEBookItems for list of edition OLIDs"

        let urlString = IAEBookItemListDownloadOperation.urlString( editionKeys )
        
        let url = URL( string: urlString )!
        let task = URLSession.shared.jsonDownloadTaskWithURL( url ) {
            
            url, response, error in
            
            self.downloadFinished(url, response: response as? HTTPURLResponse, error: error)
        }
        
        let taskOperation = URLSessionTaskOperation(task: task)
        
        let reachabilityCondition = ReachabilityCondition(host: url)
        taskOperation.addCondition(reachabilityCondition)
        
        let networkObserver = NetworkObserver()
        taskOperation.addObserver(networkObserver)
        
        addOperation(taskOperation)
    }
    
    func downloadFinished(_ url: URL?, response: HTTPURLResponse?, error: Error?) {
        if let localURL = url {
            do {
                /*
                    If we already have a file at this location, just delete it.
                    Also, swallow the error, because we don't really care about it.
                */
                try FileManager.default.removeItem(at: cacheFile)
            }
            catch { }
            
            do {
                try FileManager.default.moveItem(at: localURL, to: cacheFile)
            }
            catch let error as NSError {
                aggregateError(error)
            }
            
        }
        else if let error = error {
            aggregateError( error as NSError )
        }
        else {
            // Do nothing, and the operation will automatically finish.
        }
    }
}
