//  BookDownloadOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/2/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation

import PSOperations

class BookDownloadOperation: GroupOperation {
    // MARK: Properties
    let cacheBookURL: URL

    // MARK: Initialization
    
    /// - parameter cacheFile: The file `NSURL` to which the eBook will be downloaded.
    init( cacheBookURL: URL, remoteBookURL: URL ) {

        self.cacheBookURL = cacheBookURL

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
        let task = URLSession.shared.downloadTask( with: remoteBookURL, completionHandler: downloadFinished )
        
        let taskOperation = URLSessionTaskOperation(task: task)
        
        let reachabilityCondition = ReachabilityCondition( host: remoteBookURL )
        taskOperation.addCondition(reachabilityCondition)

        let networkObserver = NetworkObserver()
        taskOperation.addObserver(networkObserver)
        
        addOperation(taskOperation)
    }
    
    func downloadFinished( _ url: URL?, response: URLResponse?, error: Error? ) -> Void {
        
        if let error = error {

            aggregateError( error as NSError )

        } else if let tempURL = url {
            
            do {
                /*
                    If we already have a file at this location, just delete it.
                    Also, swallow the error, because we don't really care about it.
                */
                try FileManager.default.removeItem( at: self.cacheBookURL )
            }
            catch {}
            
            do {
                
                try FileManager.default.moveItem( at: tempURL, to: self.cacheBookURL )
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
