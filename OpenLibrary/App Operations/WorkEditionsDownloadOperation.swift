//  WorkEditionsDownloadOperation
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation

import PSOperations

class WorkEditionsDownloadOperation: GroupOperation {
    // MARK: Properties

    let cacheFile: URL
    
    // MARK: Initialization
    
    /// - parameter cacheFile: The file `NSURL` to which the list of author Editions will be downloaded.
    init( queryText: String, offset: Int, limit: Int, cacheFile: URL) {

        self.cacheFile = cacheFile
        super.init(operations: [])
        name = "Download Work Editions"
        
        /*
            If this server is out of our control and does not offer a secure
            communication channel, use the http version of the URL and add
            the domain to the "NSExceptionDomains" value in the
            app's Info.plist file. When you communicate with your own servers,
            or when the services you use offer secure communication options, you
            should always prefer to use https.
        */
        let query = queryText.encodeForUrl()
        let urlString =
            "https://openlibrary.org\(query)/editions.json?offset=\(offset)&limit=\(limit)&*="
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

        guard let localURL = url else {
            
            if let error = error {
                aggregateError( error as NSError )
            }
            return
        }
        
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
            aggregateError( error )
        }
        
        if let error = validateStreamMIMEType( [jsonMIMEType,textMIMEType], response: response, url: cacheFile ) {
            
            aggregateError( error as NSError )
            
        }
    }
}
