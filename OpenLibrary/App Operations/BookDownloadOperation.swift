//  BookDownloadOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/2/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation

class BookDownloadOperation: GroupOperation {
    // MARK: Properties
    let bookURL: NSURL

    // MARK: Initialization
    
    /// - parameter cacheFile: The file `NSURL` to which the earthquake feed will be downloaded.
    init( stringID: String, bookKeyName: String, size: String, type: String, bookURL: NSURL ) {

        self.bookURL = bookURL

        super.init(operations: [])
        name = "Download book"
        
        /*
            If this server is out of our control and does not offer a secure
            communication channel, use the http version of the URL and add
            the domain to the "NSExceptionDomains" value in the
            app's Info.plist file. When you communicate with your own servers,
            or when the services you use offer secure communication options, you
            should always prefer to use https.
        */
        let urlString = "https://covers.openlibrary.org/\(type)/\(bookKeyName)/\(stringID)-\(size).jpg?default=false"
        let url = NSURL( string: urlString )!
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
    
    func downloadFinished( url: NSURL?, response: NSHTTPURLResponse?, error: NSError? ) {
        
        if let error = error {

            aggregateError( error )

        } else if let localURL = url {
            
            do {
                /*
                    If we already have a file at this location, just delete it.
                    Also, swallow the error, because we don't really care about it.
                */
                try NSFileManager.defaultManager().removeItemAtURL( self.bookURL )
            }
            catch {}
            
            if let directoryURL = self.bookURL.URLByDeletingLastPathComponent {

                do {
                    try NSFileManager.defaultManager().createDirectoryAtURL( directoryURL, withIntermediateDirectories: true, attributes: nil )
                }
                catch let error as NSError {
                    print( "\(error)" )
                }
            }

            do {
                
                try NSFileManager.defaultManager().moveItemAtURL( localURL, toURL: self.bookURL )
            }
            catch let error as NSError {
                aggregateError(error)
            }
            
        }
        else {
            // Do nothing, and the operation will automatically finish.
        }
    }
}
