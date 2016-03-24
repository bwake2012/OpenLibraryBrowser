//  AuthorEditionsDownloadOperation
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation

class AuthorEditionsDownloadOperation: GroupOperation {
    // MARK: Properties

    let cacheFile: NSURL
    
    // MARK: Initialization
    
    /// - parameter cacheFile: The file `NSURL` to which the list of author Editions will be downloaded.
    init( queryText: String, offset: Int, cacheFile: NSURL) {

        self.cacheFile = cacheFile
        super.init(operations: [])
        name = "Download Author Editions"
        
        /*
            If this server is out of our control and does not offer a secure
            communication channel, use the http version of the URL and add
            the domain to the "NSExceptionDomains" value in the
            app's Info.plist file. When you communicate with your own servers,
            or when the services you use offer secure communication options, you
            should always prefer to use https.
        */
        // ?type=/type/edition&*=&authors=/authors/OL26320A
        let query = queryText.stringByAddingPercentEncodingForRFC3986()!
        let urlString =
            "https://openlibrary.org/query.json?type=/type/edition&authors=/authors/\(query)&*="
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
        
        print( urlString )
    }
    
    deinit {
        
        print( "\(self.dynamicType.description()) deinit" )
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
