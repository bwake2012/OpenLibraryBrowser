//
//  OLReachabilityDownloadOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 7/17/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

import PSOperations

class OLReachabilityDownloadOperation: GroupOperation {

    static let indexHTMLOpenLibrary404 = "<html><head><title>404 Not Found</title></head><body bgcolor=\"white\"><center><h1>404 Not Found</h1></center><hr><center>nginx/1.4.6 (Ubuntu)</center></body></html>"

    init( host: String ) {
        
        super.init(operations: [])
        
        let urlString = "https://openlibrary.org/index.html"
        let url = NSURL( string: urlString )!
        let task = NSURLSession.sharedSession().dataTaskWithURL( url ) {
            
            data, response, error in
            
            self.downloadFinished( data, response: response as? NSHTTPURLResponse, error: error )
        }
        
        let taskOperation = URLSessionTaskOperation(task: task)
        
        let reachabilityCondition = ReachabilityCondition(host: url)
        taskOperation.addCondition(reachabilityCondition)
        
        let networkObserver = NetworkObserver()
        taskOperation.addObserver(networkObserver)
        
        addOperation( taskOperation )
    }
    
    
    func downloadFinished( data: NSData?, response: NSHTTPURLResponse?, error: NSError? ) {

        if let data = data {
            
            let dataString = NSString( data: data, encoding: NSUTF8StringEncoding )
            if let dataString = dataString {
            
                let massagedString =
                    String( dataString ).stringByReplacingOccurrencesOfString( "\r\n", withString: "" )
                if massagedString != OLReachabilityDownloadOperation.indexHTMLOpenLibrary404 {
                    
                    print( "unexpected result:\n\(massagedString)" )
                }
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
